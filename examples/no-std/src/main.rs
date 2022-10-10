#![no_std]
#![no_main]

use cortex_m_rt::entry;

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo<'_>) -> ! {
    loop {}
}

#[entry]
fn main() -> ! {
    loop {}
}
