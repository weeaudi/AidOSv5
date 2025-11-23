#pragma once

#include "std/stdint.h"

namespace shared::pci {

enum class PciBusInitStatus { Ok = 0, InvalidSig, NoMechanism, LowVersion };
enum class PciBusEnumerateStatus { Ok = 0 };

class PciBus {
  private:
    /*
    pci_sig:       dd 0          ; expected 0x20494350 ('PCI ')
    pci_pm_entry:  dd 0          ; protected-mode entry point (physical)
    pci_hwchr:     db 0          ; bit0=mech1, bit1=mech2, bit4/5=special cycle mechs
    pci_lastbus:   db 0
    pci_ver:       dw 0          ; BH:BL = BCD version (e.g., 0x0201 = 2.01)
    */

    uint32_t m_sig;
    uint32_t m_entry;
    uint8_t m_hwchr;
    uint8_t m_last_bus;
    uint16_t m_version;

  public:
    PciBus() = default;
    ~PciBus() = default;

    PciBusInitStatus init(uint32_t sig, uint32_t entry, uint8_t hwchr, uint8_t last_bus,
                          uint16_t version);
};

} // namespace shared::pci
