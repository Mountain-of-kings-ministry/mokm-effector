#include "VST3Instance.h"
#include <QDebug>
#include "public.sdk/source/vst/hosting/hostclasses.h"
#include "pluginterfaces/base/ustring.h"

using namespace Steinberg;
using namespace Steinberg::Vst;

// Helper to convert QString (UUID format) to TUID
static bool stringToTUID(const QString &cid, TUID tuid)
{
    bool ok;
    QString clean = cid;
    if (clean.startsWith('{')) clean.remove(0, 1);
    if (clean.endsWith('}')) clean.chop(1);
    clean.remove('-');

    if (clean.length() != 32) return false;

    for (int i = 0; i < 16; ++i) {
        tuid[i] = (uint8)clean.mid(i * 2, 2).toUInt(&ok, 16);
        if (!ok) return false;
    }
    return true;
}

VST3Instance::VST3Instance(const QString &pluginPath, const QString &cid, QObject *parent)
    : QObject(parent)
    , m_pluginPath(pluginPath)
    , m_cid(cid)
{
}

VST3Instance::~VST3Instance()
{
    unload();
}

bool VST3Instance::load()
{
    if (m_component) return true;

    m_module = VST3::Hosting::Module::create(m_pluginPath.toStdString(), nullptr);
    if (!m_module) {
        qWarning() << "Failed to load VST3 module:" << m_pluginPath;
        return false;
    }

    auto factory = m_module->getFactory();
    TUID tuid;
    if (!stringToTUID(m_cid, tuid)) {
        qWarning() << "Invalid CID:" << m_cid;
        return false;
    }

    if (factory.createInstance(tuid, IComponent::iid, (void**)&m_component) != kResultOk) {
        qWarning() << "Failed to create VST3 component instance";
        return false;
    }

    // Initialize component
    // In a real host, we'd pass a host context here
    m_component->initialize(nullptr);

    // Try to get edit controller
    TUID controllerId;
    if (m_component->getControllerClassId(controllerId) == kResultOk) {
        factory.createInstance(controllerId, IEditController::iid, (void**)&m_editController);
    } else {
        // Many plugins implement both interfaces in the same class
        m_component->queryInterface(IEditController::iid, (void**)&m_editController);
    }

    if (m_editController) {
        m_editController->initialize(nullptr);
        m_editController->setComponentHandler(nullptr); // Host should provide this
        
        // Connect component and controller
        FUnknownPtr<IConnectionPoint> cp1(m_component);
        FUnknownPtr<IConnectionPoint> cp2(m_editController);
        if (cp1 && cp2) {
            cp1->connect(cp2);
            cp2->connect(cp1);
        }

        // Populate initial parameters
        int32 paramCount = m_editController->getParameterCount();
        for (int32 i = 0; i < paramCount; ++i) {
            ParameterInfo info;
            if (m_editController->getParameterInfo(i, info) == kResultOk) {
                // We only automate non-read-only parameters
                if (!(info.flags & ParameterInfo::kIsReadOnly)) {
                    double val = m_editController->getParamNormalized(info.id);
                    m_parameters.insert(QString::number(info.id), val);
                }
            }
        }
    }

    m_active = true;
    emit activeChanged();
    if (!m_parameters.isEmpty())
        emit parametersChanged();
    return true;
}

void VST3Instance::unload()
{
    if (!m_component) return;

    deactivate();

    if (m_editController) {
        m_editController->terminate();
        m_editController = nullptr;
    }

    m_component->terminate();
    m_component = nullptr;
    m_module = nullptr;

    m_active = false;
    emit activeChanged();
}

bool VST3Instance::activate(double sampleRate, int maxFrames)
{
    if (!m_component) return false;

    ProcessSetup setup;
    setup.processMode = kRealtime;
    setup.symbolicSampleSize = kSample32;
    setup.maxSamplesPerBlock = maxFrames;
    setup.sampleRate = sampleRate;

    if (m_component->setupProcessing(setup) != kResultOk)
        return false;

    return m_component->setActive(true) == kResultOk;
}

void VST3Instance::deactivate()
{
    if (m_component)
        m_component->setActive(false);
}

void VST3Instance::setParameter(const QString &paramId, double value)
{
    if (!m_editController || !m_component) return;

    bool ok;
    ParamID id = static_cast<ParamID>(paramId.toUInt(&ok));
    if (!ok) return;

    // Update edit controller
    m_editController->setParamNormalized(id, value);

    // In a real host, we'd use IParameterChanges to send this to the processor
    // For now, we update the local map and assume the plugin handles it if it's single-component
    m_parameters[paramId] = value;
    emit parametersChanged();
}

double VST3Instance::getParameter(const QString &paramId) const
{
    if (!m_editController) return 0.0;
    bool ok;
    ParamID id = static_cast<ParamID>(paramId.toUInt(&ok));
    if (!ok) return 0.0;
    return m_editController->getParamNormalized(id);
}

bool VST3Instance::process(float **inputs, float **outputs, int nChannels, int nFrames)
{
    if (!m_component || !m_active) return false;

    ProcessData data;
    data.processMode = kRealtime;
    data.symbolicSampleSize = kSample32;
    data.numSamples = nFrames;
    
    // We assume 1 bus for simplicity here
    AudioBusBuffers inBus;
    inBus.numChannels = nChannels;
    inBus.channelBuffers32 = inputs;
    data.numInputs = 1;
    data.inputs = &inBus;

    AudioBusBuffers outBus;
    outBus.numChannels = nChannels;
    outBus.channelBuffers32 = outputs;
    data.numOutputs = 1;
    data.outputs = &outBus;

    return m_component->process(data) == kResultOk;
}
