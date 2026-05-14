#include "CLAPInstance.h"

#ifdef MOKM_ENABLE_CLAP
#include <dlfcn.h>
#include <clap/clap.h>
#include <clap/ext/params.h>
#include <clap/events.h>
#include <clap/factory/plugin-factory.h>
#include <cstring>
#include <cmath>

// ── Host extension helpers ──────────────────────────────────
static const void* hostGetExtension(const clap_host_t *host, const char *extensionId)
{
    Q_UNUSED(host)
    Q_UNUSED(extensionId)
    return nullptr;
}

static void hostRequestRestart(const clap_host_t *host) { Q_UNUSED(host) }
static void hostRequestProcess(const clap_host_t *host) { Q_UNUSED(host) }
static void hostRequestCallback(const clap_host_t *host) { Q_UNUSED(host) }

static const clap_host_t s_host = {
    .clap_version = CLAP_VERSION,
    .host_data = nullptr,
    .name = "MOKM Effector",
    .vendor = "MOKM",
    .url = "https://mokm.app",
    .version = "0.1",
    .get_extension = hostGetExtension,
    .request_restart = hostRequestRestart,
    .request_process = hostRequestProcess,
    .request_callback = hostRequestCallback,
};

// ── Simple input event list for flush ──────────────────────
struct FlushEventList {
    clap_input_events_t iface;
    clap_event_param_value_t events[64];
    uint32_t count = 0;

    static uint32_t size(const clap_input_events_t *list) {
        auto *self = reinterpret_cast<const FlushEventList*>(list);
        return self->count;
    }
    static const clap_event_header_t* get(const clap_input_events_t *list, uint32_t index) {
        auto *self = reinterpret_cast<const FlushEventList*>(list);
        if (index < self->count)
            return &self->events[index].header;
        return nullptr;
    }
};

CLAPInstance::CLAPInstance(const QString &pluginId,
                           const QString &pluginPath,
                           QObject *parent)
    : QObject(parent)
    , m_pluginId(pluginId)
    , m_pluginPath(pluginPath)
{
}

CLAPInstance::~CLAPInstance()
{
    unload();
}

bool CLAPInstance::load()
{
    if (m_plugin) return true;

    m_libHandle = dlopen(m_pluginPath.toUtf8().constData(), RTLD_NOW | RTLD_LOCAL);
    if (!m_libHandle) return false;

    auto entry = (const clap_plugin_entry_t *)dlsym(m_libHandle, "clap_entry");
    if (!entry || !entry->init) {
        dlclose(m_libHandle);
        m_libHandle = nullptr;
        return false;
    }

    if (!entry->init(m_pluginPath.toUtf8().constData())) {
        dlclose(m_libHandle);
        m_libHandle = nullptr;
        return false;
    }

    auto factory = (const clap_plugin_factory_t *)entry->get_factory(CLAP_PLUGIN_FACTORY_ID);
    if (!factory) {
        entry->deinit();
        dlclose(m_libHandle);
        m_libHandle = nullptr;
        return false;
    }

    uint32_t count = factory->get_plugin_count(factory);
    for (uint32_t i = 0; i < count; ++i) {
        const auto *desc = factory->get_plugin_descriptor(factory, i);
        if (desc && desc->id && m_pluginId == QString::fromUtf8(desc->id)) {
            auto *plug = factory->create_plugin(factory, &s_host, desc->id);
            if (plug) {
                plug->init(plug);
                m_plugin = const_cast<clap_plugin_t *>(plug);
                m_name = QString::fromUtf8(desc->name);
                emit nameChanged();
            }
            break;
        }
    }

    if (!m_plugin) {
        entry->deinit();
        dlclose(m_libHandle);
        m_libHandle = nullptr;
        return false;
    }

    auto *plug = static_cast<const clap_plugin_t *>(m_plugin);
    auto *params = (const clap_plugin_params_t *)plug->get_extension(plug, CLAP_EXT_PARAMS);
    if (params) {
        uint32_t paramCount = params->count(plug);
        for (uint32_t i = 0; i < paramCount; ++i) {
            clap_param_info_t info;
            if (params->get_info(plug, i, &info)) {
                double val = 0.0;
                params->get_value(plug, info.id, &val);
                m_parameters.insert(QString::number(info.id), QVariant(val));
            }
        }
    }

    m_active = true;
    emit activeChanged();
    if (!m_parameters.isEmpty())
        emit parametersChanged();
    return true;
}

void CLAPInstance::unload()
{
    if (!m_libHandle) return;

    if (m_plugin) {
        deactivate();
        auto *plug = static_cast<const clap_plugin_t *>(m_plugin);
        plug->destroy(plug);
        m_plugin = nullptr;
    }

    auto entry = (const clap_plugin_entry_t *)dlsym(m_libHandle, "clap_entry");
    if (entry && entry->deinit)
        entry->deinit();

    dlclose(m_libHandle);
    m_libHandle = nullptr;
    m_active = false;
    m_parameters.clear();
    emit activeChanged();
    emit parametersChanged();
}

bool CLAPInstance::activate(double sampleRate, int minFrames, int maxFrames)
{
    auto *plug = static_cast<const clap_plugin_t *>(m_plugin);
    if (!plug) return false;
    return plug->activate(plug, sampleRate, static_cast<uint32_t>(minFrames), static_cast<uint32_t>(maxFrames));
}

void CLAPInstance::deactivate()
{
    auto *plug = static_cast<const clap_plugin_t *>(m_plugin);
    if (!plug) return;
    plug->stop_processing(plug);
    plug->deactivate(plug);
}

void CLAPInstance::setParameter(const QString &paramId, double value)
{
    auto *plug = static_cast<const clap_plugin_t *>(m_plugin);
    if (!plug) return;
    auto *params = (const clap_plugin_params_t *)plug->get_extension(plug, CLAP_EXT_PARAMS);
    if (!params) return;

    clap_id id = static_cast<clap_id>(paramId.toUInt());

    // Send parameter change via flush
    FlushEventList evList;
    auto &ev = evList.events[0];
    std::memset(&ev, 0, sizeof(ev));
    ev.header.size = sizeof(clap_event_param_value_t);
    ev.header.time = 0;
    ev.header.type = CLAP_EVENT_PARAM_VALUE;
    ev.header.flags = 0;
    ev.param_id = id;
    ev.value = value;
    ev.cookie = nullptr;
    evList.count = 1;

    evList.iface.size = &FlushEventList::size;
    evList.iface.get = &FlushEventList::get;
    params->flush(plug, &evList.iface, nullptr);

    m_parameters[paramId] = QVariant(value);
    emit parametersChanged();
}

double CLAPInstance::getParameter(const QString &paramId) const
{
    return m_parameters.value(paramId, 0.0).toDouble();
}

bool CLAPInstance::process(float *const *audioInputs, float **audioOutputs,
                            uint32_t nChannels, uint32_t nFrames)
{
    auto *plug = static_cast<const clap_plugin_t *>(m_plugin);
    if (!plug) return false;

    plug->start_processing(plug);

    QVector<clap_audio_buffer_t> inputBufs(1);
    inputBufs[0].data32 = const_cast<float**>(audioInputs);
    inputBufs[0].data64 = nullptr;
    inputBufs[0].channel_count = nChannels;
    inputBufs[0].latency = 0;
    inputBufs[0].constant_mask = 0;

    QVector<clap_audio_buffer_t> outputBufs(1);
    outputBufs[0].data32 = audioOutputs;
    outputBufs[0].data64 = nullptr;
    outputBufs[0].channel_count = nChannels;
    outputBufs[0].latency = 0;
    outputBufs[0].constant_mask = 0;

    clap_process_t process;
    std::memset(&process, 0, sizeof(process));
    process.steady_time = -1;
    process.frames_count = nFrames;
    process.transport = nullptr;
    process.audio_inputs = inputBufs.constData();
    process.audio_outputs = outputBufs.data();
    process.audio_inputs_count = 1;
    process.audio_outputs_count = 1;
    process.in_events = nullptr;
    process.out_events = nullptr;

    auto status = plug->process(plug, &process);
    plug->stop_processing(plug);
    return status == CLAP_PROCESS_CONTINUE || status == CLAP_PROCESS_TAIL;
}
#else
CLAPInstance::CLAPInstance(const QString &, const QString &, QObject *parent) : QObject(parent) {}
CLAPInstance::~CLAPInstance() {}
bool CLAPInstance::load() { return false; }
void CLAPInstance::unload() {}
bool CLAPInstance::activate(double, int, int) { return false; }
void CLAPInstance::deactivate() {}
void CLAPInstance::setParameter(const QString &, double) {}
double CLAPInstance::getParameter(const QString &) const { return 0.0; }
bool CLAPInstance::process(float *const *, float **, uint32_t, uint32_t) { return false; }
#endif
