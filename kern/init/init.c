#include <clock.h>
#include <console.h>
#include <defs.h>
#include <intr.h>
#include <kdebug.h>
#include <kmonitor.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <dtb.h>

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
    dtb_init();
    cons_init();  // init the console
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);

    print_kerninfo();

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table

    pmm_init();  // init physical memory management

    idt_init();  // init interrupt descriptor table

    // ======================== 断点异常测试模块 ========================
    // 定义一个 volatile 的局部变量 test，并在 ebreak 前修改它的值。
    // volatile 关键字确保编译器不会将此变量优化到寄存器中，而是会真正在栈上为其分配空间，
    // 以便我们后续在断点异常处理器中，通过检查栈内存来验证调试功能。
    volatile int test=9;
    test++;
    // 在触发断点前打印信息，用于验证程序执行流是否到达此处。
    cprintf("+++ Triggering a breakpoint exception! +++\n");
    // 通过内联汇编执行 ebreak 指令，这将主动触发一个同步的断点异常。
    // CPU 会立即暂停当前执行，并跳转到 stvec 指向的 __alltraps 入口。
    asm volatile ("ebreak");
    // 如果这条 cprintf 被成功打印，则证明我们的异常处理程序已经正确地从异常中恢复，
    // 并且将执行流返回到了 ebreak 指令的下一条指令。
    cprintf("+++ Breakpoint exception handled, resuming. +++\n");
    clock_init();   // init clock interrupt
    intr_enable();  // enable irq interrupt

    /* do nothing */
    while (1)
        ;
}

void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
    mon_backtrace(0, NULL, NULL);
}

void __attribute__((noinline)) grade_backtrace1(int arg0, int arg1) {
    grade_backtrace2(arg0, (uintptr_t)&arg0, arg1, (uintptr_t)&arg1);
}

void __attribute__((noinline)) grade_backtrace0(int arg0, int arg1, int arg2) {
    grade_backtrace1(arg0, arg2);
}

void grade_backtrace(void) { grade_backtrace0(0, (uintptr_t)kern_init, 0xffff0000); }

