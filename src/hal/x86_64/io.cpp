#include "hal/io.hpp"

namespace hal::io {
uint8_t inb(uint16_t port)
{
    uint8_t v;
    asm volatile("inb %1,%0" : "=a"(v) : "Nd"(port));
    return v;
}
void outb(uint16_t port, uint8_t v) { asm volatile("outb %0,%1" ::"a"(v), "Nd"(port)); }
uint16_t inw(uint16_t port)
{
    uint16_t v;
    asm volatile("inw %1,%0" : "=a"(v) : "Nd"(port));
    return v;
}
void outw(uint16_t port, uint16_t v) { asm volatile("outw %0,%1" ::"a"(v), "Nd"(port)); }
uint32_t inl(uint16_t port)
{
    uint32_t v;
    asm volatile("inl %1,%0" : "=a"(v) : "Nd"(port));
    return v;
}
void outl(uint16_t port, uint32_t v) { asm volatile("outl %0,%1" ::"a"(v), "Nd"(port)); }
} // namespace hal::io