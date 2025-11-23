#include "shared/pci.hpp"

namespace shared::pci {

PciBusInitStatus PciBus::init(uint32_t sig, uint32_t entry, uint8_t hwchr, uint8_t last_bus,
                              uint16_t version)
{
    m_sig = sig;
    m_entry = entry;
    m_hwchr = hwchr;
    m_last_bus = last_bus;
    m_version = version;

    // 'PCI ' signature
    if(m_sig != 0x20494350u)
        return PciBusInitStatus::InvalidSig;

    // must support at least one mechanism (mech1 or mech2)
    if(!(m_hwchr & 0x01u) && !(m_hwchr & 0x02u))
        return PciBusInitStatus::NoMechanism;

    // require PCI BIOS version >= 2.00 (0x0200)
    if(m_version < 0x0200u)
        return PciBusInitStatus::LowVersion;

    // Basics are in order
    return PciBusInitStatus::Ok;
}

} // namespace shared::pci
