/* brief: stage2 loader
 * context: boot-only
 * notes: Loads the kernel
 */

#include "shared/pci.hpp"
#include "std/stdint.h"

namespace aidos::stage2 {

extern "C" uint32_t rsdp;

/*
pci_sig:       dd 0          ; expected 0x20494350 ('PCI ')
pci_pm_entry:  dd 0          ; protected-mode entry point (physical)
pci_hwchr:     db 0          ; bit0=mech1, bit1=mech2, bit4/5=special cycle mechs
pci_lastbus:   db 0
pci_ver:       dw 0          ; BH:BL = BCD version (e.g., 0x0201 = 2.01)
*/

extern "C" uint32_t pci_sig;
extern "C" uint32_t pci_pm_entry;
extern "C" uint8_t pci_hwchr;
extern "C" uint8_t pci_lastbus;
extern "C" uint16_t pci_ver;

using init_func_t = void (*)(void);

extern "C" {
extern init_func_t __init_array_start[];
extern init_func_t __init_array_end[];
}

static void run_init_array()
{
    const init_func_t InvalidFn =
        reinterpret_cast<init_func_t>(~uintptr_t{0}); // 0xFFFFFFFF... for this width

    for(init_func_t *p = __init_array_start; p != __init_array_end; ++p) {
        init_func_t f = *p;

        if(!f || f == InvalidFn)
            continue;

        f();
    }
}

extern "C" void aidos_stage2_main()
{
    run_init_array();

    // Calculate rsdp address
    uint16_t seg = (rsdp >> 16) & 0xFFFF;
    uint16_t off = rsdp & 0xFFFF;
    __attribute__((unused)) uint32_t rsdp_addr = ((uint32_t)seg << 4) + off;

    shared::pci::PciBus pciBus;
    shared::pci::PciBusInitStatus status =
        pciBus.init(pci_sig, pci_pm_entry, pci_hwchr, pci_lastbus, pci_ver);
    if(status != shared::pci::PciBusInitStatus::Ok) {
        while(true) {
        }
    }
}
} // namespace aidos::stage2
