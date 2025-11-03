
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0206337          	lui	t1,0xc0206
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200054:	00007517          	auipc	a0,0x7
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0207028 <free_area>
ffffffffc020005c:	00007617          	auipc	a2,0x7
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02074a0 <end>
int kern_init(void) {
ffffffffc0200064:	1101                	addi	sp,sp,-32
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	ec06                	sd	ra,24(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	703010ef          	jal	ra,ffffffffc0201f6e <memset>
    dtb_init();
ffffffffc0200070:	432000ef          	jal	ra,ffffffffc02004a2 <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	420000ef          	jal	ra,ffffffffc0200494 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	f7050513          	addi	a0,a0,-144 # ffffffffc0201fe8 <etext+0x68>
ffffffffc0200080:	0b4000ef          	jal	ra,ffffffffc0200134 <cputs>

    print_kerninfo();
ffffffffc0200084:	100000ef          	jal	ra,ffffffffc0200184 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	0d1000ef          	jal	ra,ffffffffc0200958 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	766010ef          	jal	ra,ffffffffc02017f2 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	0c9000ef          	jal	ra,ffffffffc0200958 <idt_init>

    // ======================== 断点异常测试模块 ========================
    // 定义一个 volatile 的局部变量 test，并在 ebreak 前修改它的值。
    // volatile 关键字确保编译器不会将此变量优化到寄存器中，而是会真正在栈上为其分配空间，
    // 以便我们后续在断点异常处理器中，通过检查栈内存来验证调试功能。
    volatile int test=9;
ffffffffc0200094:	47a5                	li	a5,9
ffffffffc0200096:	c63e                	sw	a5,12(sp)
    test++;
ffffffffc0200098:	47b2                	lw	a5,12(sp)
    // 在触发断点前打印信息，用于验证程序执行流是否到达此处。
    cprintf("+++ Triggering a breakpoint exception! +++\n");
ffffffffc020009a:	00002517          	auipc	a0,0x2
ffffffffc020009e:	ee650513          	addi	a0,a0,-282 # ffffffffc0201f80 <etext>
    test++;
ffffffffc02000a2:	2785                	addiw	a5,a5,1
ffffffffc02000a4:	c63e                	sw	a5,12(sp)
    cprintf("+++ Triggering a breakpoint exception! +++\n");
ffffffffc02000a6:	056000ef          	jal	ra,ffffffffc02000fc <cprintf>
    // 通过内联汇编执行 ebreak 指令，这将主动触发一个同步的断点异常。
    // CPU 会立即暂停当前执行，并跳转到 stvec 指向的 __alltraps 入口。
    asm volatile ("ebreak");
ffffffffc02000aa:	9002                	ebreak
    // 如果这条 cprintf 被成功打印，则证明我们的异常处理程序已经正确地从异常中恢复，
    // 并且将执行流返回到了 ebreak 指令的下一条指令。
    cprintf("+++ Breakpoint exception handled, resuming. +++\n");
ffffffffc02000ac:	00002517          	auipc	a0,0x2
ffffffffc02000b0:	f0450513          	addi	a0,a0,-252 # ffffffffc0201fb0 <etext+0x30>
ffffffffc02000b4:	048000ef          	jal	ra,ffffffffc02000fc <cprintf>
    clock_init();   // init clock interrupt
ffffffffc02000b8:	39a000ef          	jal	ra,ffffffffc0200452 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc02000bc:	796000ef          	jal	ra,ffffffffc0200852 <intr_enable>

    /* do nothing */
    while (1)
ffffffffc02000c0:	a001                	j	ffffffffc02000c0 <kern_init+0x6c>

ffffffffc02000c2 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000c2:	1141                	addi	sp,sp,-16
ffffffffc02000c4:	e022                	sd	s0,0(sp)
ffffffffc02000c6:	e406                	sd	ra,8(sp)
ffffffffc02000c8:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000ca:	3cc000ef          	jal	ra,ffffffffc0200496 <cons_putc>
    (*cnt) ++;
ffffffffc02000ce:	401c                	lw	a5,0(s0)
}
ffffffffc02000d0:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000d2:	2785                	addiw	a5,a5,1
ffffffffc02000d4:	c01c                	sw	a5,0(s0)
}
ffffffffc02000d6:	6402                	ld	s0,0(sp)
ffffffffc02000d8:	0141                	addi	sp,sp,16
ffffffffc02000da:	8082                	ret

ffffffffc02000dc <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000dc:	1101                	addi	sp,sp,-32
ffffffffc02000de:	862a                	mv	a2,a0
ffffffffc02000e0:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e2:	00000517          	auipc	a0,0x0
ffffffffc02000e6:	fe050513          	addi	a0,a0,-32 # ffffffffc02000c2 <cputch>
ffffffffc02000ea:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000ec:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ee:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000f0:	14f010ef          	jal	ra,ffffffffc0201a3e <vprintfmt>
    return cnt;
}
ffffffffc02000f4:	60e2                	ld	ra,24(sp)
ffffffffc02000f6:	4532                	lw	a0,12(sp)
ffffffffc02000f8:	6105                	addi	sp,sp,32
ffffffffc02000fa:	8082                	ret

ffffffffc02000fc <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000fc:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000fe:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200102:	8e2a                	mv	t3,a0
ffffffffc0200104:	f42e                	sd	a1,40(sp)
ffffffffc0200106:	f832                	sd	a2,48(sp)
ffffffffc0200108:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020010a:	00000517          	auipc	a0,0x0
ffffffffc020010e:	fb850513          	addi	a0,a0,-72 # ffffffffc02000c2 <cputch>
ffffffffc0200112:	004c                	addi	a1,sp,4
ffffffffc0200114:	869a                	mv	a3,t1
ffffffffc0200116:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200118:	ec06                	sd	ra,24(sp)
ffffffffc020011a:	e0ba                	sd	a4,64(sp)
ffffffffc020011c:	e4be                	sd	a5,72(sp)
ffffffffc020011e:	e8c2                	sd	a6,80(sp)
ffffffffc0200120:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200122:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200124:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200126:	119010ef          	jal	ra,ffffffffc0201a3e <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020012a:	60e2                	ld	ra,24(sp)
ffffffffc020012c:	4512                	lw	a0,4(sp)
ffffffffc020012e:	6125                	addi	sp,sp,96
ffffffffc0200130:	8082                	ret

ffffffffc0200132 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200132:	a695                	j	ffffffffc0200496 <cons_putc>

ffffffffc0200134 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200134:	1101                	addi	sp,sp,-32
ffffffffc0200136:	e822                	sd	s0,16(sp)
ffffffffc0200138:	ec06                	sd	ra,24(sp)
ffffffffc020013a:	e426                	sd	s1,8(sp)
ffffffffc020013c:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020013e:	00054503          	lbu	a0,0(a0)
ffffffffc0200142:	c51d                	beqz	a0,ffffffffc0200170 <cputs+0x3c>
ffffffffc0200144:	0405                	addi	s0,s0,1
ffffffffc0200146:	4485                	li	s1,1
ffffffffc0200148:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc020014a:	34c000ef          	jal	ra,ffffffffc0200496 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020014e:	00044503          	lbu	a0,0(s0)
ffffffffc0200152:	008487bb          	addw	a5,s1,s0
ffffffffc0200156:	0405                	addi	s0,s0,1
ffffffffc0200158:	f96d                	bnez	a0,ffffffffc020014a <cputs+0x16>
    (*cnt) ++;
ffffffffc020015a:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020015e:	4529                	li	a0,10
ffffffffc0200160:	336000ef          	jal	ra,ffffffffc0200496 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200164:	60e2                	ld	ra,24(sp)
ffffffffc0200166:	8522                	mv	a0,s0
ffffffffc0200168:	6442                	ld	s0,16(sp)
ffffffffc020016a:	64a2                	ld	s1,8(sp)
ffffffffc020016c:	6105                	addi	sp,sp,32
ffffffffc020016e:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200170:	4405                	li	s0,1
ffffffffc0200172:	b7f5                	j	ffffffffc020015e <cputs+0x2a>

ffffffffc0200174 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200174:	1141                	addi	sp,sp,-16
ffffffffc0200176:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200178:	326000ef          	jal	ra,ffffffffc020049e <cons_getc>
ffffffffc020017c:	dd75                	beqz	a0,ffffffffc0200178 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020017e:	60a2                	ld	ra,8(sp)
ffffffffc0200180:	0141                	addi	sp,sp,16
ffffffffc0200182:	8082                	ret

ffffffffc0200184 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200184:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200186:	00002517          	auipc	a0,0x2
ffffffffc020018a:	e8250513          	addi	a0,a0,-382 # ffffffffc0202008 <etext+0x88>
void print_kerninfo(void) {
ffffffffc020018e:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200190:	f6dff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200194:	00000597          	auipc	a1,0x0
ffffffffc0200198:	ec058593          	addi	a1,a1,-320 # ffffffffc0200054 <kern_init>
ffffffffc020019c:	00002517          	auipc	a0,0x2
ffffffffc02001a0:	e8c50513          	addi	a0,a0,-372 # ffffffffc0202028 <etext+0xa8>
ffffffffc02001a4:	f59ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001a8:	00002597          	auipc	a1,0x2
ffffffffc02001ac:	dd858593          	addi	a1,a1,-552 # ffffffffc0201f80 <etext>
ffffffffc02001b0:	00002517          	auipc	a0,0x2
ffffffffc02001b4:	e9850513          	addi	a0,a0,-360 # ffffffffc0202048 <etext+0xc8>
ffffffffc02001b8:	f45ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001bc:	00007597          	auipc	a1,0x7
ffffffffc02001c0:	e6c58593          	addi	a1,a1,-404 # ffffffffc0207028 <free_area>
ffffffffc02001c4:	00002517          	auipc	a0,0x2
ffffffffc02001c8:	ea450513          	addi	a0,a0,-348 # ffffffffc0202068 <etext+0xe8>
ffffffffc02001cc:	f31ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001d0:	00007597          	auipc	a1,0x7
ffffffffc02001d4:	2d058593          	addi	a1,a1,720 # ffffffffc02074a0 <end>
ffffffffc02001d8:	00002517          	auipc	a0,0x2
ffffffffc02001dc:	eb050513          	addi	a0,a0,-336 # ffffffffc0202088 <etext+0x108>
ffffffffc02001e0:	f1dff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001e4:	00007597          	auipc	a1,0x7
ffffffffc02001e8:	6bb58593          	addi	a1,a1,1723 # ffffffffc020789f <end+0x3ff>
ffffffffc02001ec:	00000797          	auipc	a5,0x0
ffffffffc02001f0:	e6878793          	addi	a5,a5,-408 # ffffffffc0200054 <kern_init>
ffffffffc02001f4:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001f8:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001fc:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001fe:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200202:	95be                	add	a1,a1,a5
ffffffffc0200204:	85a9                	srai	a1,a1,0xa
ffffffffc0200206:	00002517          	auipc	a0,0x2
ffffffffc020020a:	ea250513          	addi	a0,a0,-350 # ffffffffc02020a8 <etext+0x128>
}
ffffffffc020020e:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200210:	b5f5                	j	ffffffffc02000fc <cprintf>

ffffffffc0200212 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200212:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200214:	00002617          	auipc	a2,0x2
ffffffffc0200218:	ec460613          	addi	a2,a2,-316 # ffffffffc02020d8 <etext+0x158>
ffffffffc020021c:	04d00593          	li	a1,77
ffffffffc0200220:	00002517          	auipc	a0,0x2
ffffffffc0200224:	ed050513          	addi	a0,a0,-304 # ffffffffc02020f0 <etext+0x170>
void print_stackframe(void) {
ffffffffc0200228:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020022a:	1cc000ef          	jal	ra,ffffffffc02003f6 <__panic>

ffffffffc020022e <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020022e:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200230:	00002617          	auipc	a2,0x2
ffffffffc0200234:	ed860613          	addi	a2,a2,-296 # ffffffffc0202108 <etext+0x188>
ffffffffc0200238:	00002597          	auipc	a1,0x2
ffffffffc020023c:	ef058593          	addi	a1,a1,-272 # ffffffffc0202128 <etext+0x1a8>
ffffffffc0200240:	00002517          	auipc	a0,0x2
ffffffffc0200244:	ef050513          	addi	a0,a0,-272 # ffffffffc0202130 <etext+0x1b0>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200248:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020024a:	eb3ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
ffffffffc020024e:	00002617          	auipc	a2,0x2
ffffffffc0200252:	ef260613          	addi	a2,a2,-270 # ffffffffc0202140 <etext+0x1c0>
ffffffffc0200256:	00002597          	auipc	a1,0x2
ffffffffc020025a:	f1258593          	addi	a1,a1,-238 # ffffffffc0202168 <etext+0x1e8>
ffffffffc020025e:	00002517          	auipc	a0,0x2
ffffffffc0200262:	ed250513          	addi	a0,a0,-302 # ffffffffc0202130 <etext+0x1b0>
ffffffffc0200266:	e97ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
ffffffffc020026a:	00002617          	auipc	a2,0x2
ffffffffc020026e:	f0e60613          	addi	a2,a2,-242 # ffffffffc0202178 <etext+0x1f8>
ffffffffc0200272:	00002597          	auipc	a1,0x2
ffffffffc0200276:	f2658593          	addi	a1,a1,-218 # ffffffffc0202198 <etext+0x218>
ffffffffc020027a:	00002517          	auipc	a0,0x2
ffffffffc020027e:	eb650513          	addi	a0,a0,-330 # ffffffffc0202130 <etext+0x1b0>
ffffffffc0200282:	e7bff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    }
    return 0;
}
ffffffffc0200286:	60a2                	ld	ra,8(sp)
ffffffffc0200288:	4501                	li	a0,0
ffffffffc020028a:	0141                	addi	sp,sp,16
ffffffffc020028c:	8082                	ret

ffffffffc020028e <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020028e:	1141                	addi	sp,sp,-16
ffffffffc0200290:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200292:	ef3ff0ef          	jal	ra,ffffffffc0200184 <print_kerninfo>
    return 0;
}
ffffffffc0200296:	60a2                	ld	ra,8(sp)
ffffffffc0200298:	4501                	li	a0,0
ffffffffc020029a:	0141                	addi	sp,sp,16
ffffffffc020029c:	8082                	ret

ffffffffc020029e <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020029e:	1141                	addi	sp,sp,-16
ffffffffc02002a0:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002a2:	f71ff0ef          	jal	ra,ffffffffc0200212 <print_stackframe>
    return 0;
}
ffffffffc02002a6:	60a2                	ld	ra,8(sp)
ffffffffc02002a8:	4501                	li	a0,0
ffffffffc02002aa:	0141                	addi	sp,sp,16
ffffffffc02002ac:	8082                	ret

ffffffffc02002ae <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002ae:	7115                	addi	sp,sp,-224
ffffffffc02002b0:	ed5e                	sd	s7,152(sp)
ffffffffc02002b2:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002b4:	00002517          	auipc	a0,0x2
ffffffffc02002b8:	ef450513          	addi	a0,a0,-268 # ffffffffc02021a8 <etext+0x228>
kmonitor(struct trapframe *tf) {
ffffffffc02002bc:	ed86                	sd	ra,216(sp)
ffffffffc02002be:	e9a2                	sd	s0,208(sp)
ffffffffc02002c0:	e5a6                	sd	s1,200(sp)
ffffffffc02002c2:	e1ca                	sd	s2,192(sp)
ffffffffc02002c4:	fd4e                	sd	s3,184(sp)
ffffffffc02002c6:	f952                	sd	s4,176(sp)
ffffffffc02002c8:	f556                	sd	s5,168(sp)
ffffffffc02002ca:	f15a                	sd	s6,160(sp)
ffffffffc02002cc:	e962                	sd	s8,144(sp)
ffffffffc02002ce:	e566                	sd	s9,136(sp)
ffffffffc02002d0:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002d2:	e2bff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002d6:	00002517          	auipc	a0,0x2
ffffffffc02002da:	efa50513          	addi	a0,a0,-262 # ffffffffc02021d0 <etext+0x250>
ffffffffc02002de:	e1fff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    if (tf != NULL) {
ffffffffc02002e2:	000b8563          	beqz	s7,ffffffffc02002ec <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002e6:	855e                	mv	a0,s7
ffffffffc02002e8:	051000ef          	jal	ra,ffffffffc0200b38 <print_trapframe>
ffffffffc02002ec:	00002c17          	auipc	s8,0x2
ffffffffc02002f0:	f54c0c13          	addi	s8,s8,-172 # ffffffffc0202240 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002f4:	00002917          	auipc	s2,0x2
ffffffffc02002f8:	f0490913          	addi	s2,s2,-252 # ffffffffc02021f8 <etext+0x278>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002fc:	00002497          	auipc	s1,0x2
ffffffffc0200300:	f0448493          	addi	s1,s1,-252 # ffffffffc0202200 <etext+0x280>
        if (argc == MAXARGS - 1) {
ffffffffc0200304:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200306:	00002b17          	auipc	s6,0x2
ffffffffc020030a:	f02b0b13          	addi	s6,s6,-254 # ffffffffc0202208 <etext+0x288>
        argv[argc ++] = buf;
ffffffffc020030e:	00002a17          	auipc	s4,0x2
ffffffffc0200312:	e1aa0a13          	addi	s4,s4,-486 # ffffffffc0202128 <etext+0x1a8>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200316:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200318:	854a                	mv	a0,s2
ffffffffc020031a:	2a7010ef          	jal	ra,ffffffffc0201dc0 <readline>
ffffffffc020031e:	842a                	mv	s0,a0
ffffffffc0200320:	dd65                	beqz	a0,ffffffffc0200318 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200322:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200326:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200328:	e1bd                	bnez	a1,ffffffffc020038e <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc020032a:	fe0c87e3          	beqz	s9,ffffffffc0200318 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020032e:	6582                	ld	a1,0(sp)
ffffffffc0200330:	00002d17          	auipc	s10,0x2
ffffffffc0200334:	f10d0d13          	addi	s10,s10,-240 # ffffffffc0202240 <commands>
        argv[argc ++] = buf;
ffffffffc0200338:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020033a:	4401                	li	s0,0
ffffffffc020033c:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020033e:	3d7010ef          	jal	ra,ffffffffc0201f14 <strcmp>
ffffffffc0200342:	c919                	beqz	a0,ffffffffc0200358 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200344:	2405                	addiw	s0,s0,1
ffffffffc0200346:	0b540063          	beq	s0,s5,ffffffffc02003e6 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020034a:	000d3503          	ld	a0,0(s10)
ffffffffc020034e:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200350:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200352:	3c3010ef          	jal	ra,ffffffffc0201f14 <strcmp>
ffffffffc0200356:	f57d                	bnez	a0,ffffffffc0200344 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200358:	00141793          	slli	a5,s0,0x1
ffffffffc020035c:	97a2                	add	a5,a5,s0
ffffffffc020035e:	078e                	slli	a5,a5,0x3
ffffffffc0200360:	97e2                	add	a5,a5,s8
ffffffffc0200362:	6b9c                	ld	a5,16(a5)
ffffffffc0200364:	865e                	mv	a2,s7
ffffffffc0200366:	002c                	addi	a1,sp,8
ffffffffc0200368:	fffc851b          	addiw	a0,s9,-1
ffffffffc020036c:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020036e:	fa0555e3          	bgez	a0,ffffffffc0200318 <kmonitor+0x6a>
}
ffffffffc0200372:	60ee                	ld	ra,216(sp)
ffffffffc0200374:	644e                	ld	s0,208(sp)
ffffffffc0200376:	64ae                	ld	s1,200(sp)
ffffffffc0200378:	690e                	ld	s2,192(sp)
ffffffffc020037a:	79ea                	ld	s3,184(sp)
ffffffffc020037c:	7a4a                	ld	s4,176(sp)
ffffffffc020037e:	7aaa                	ld	s5,168(sp)
ffffffffc0200380:	7b0a                	ld	s6,160(sp)
ffffffffc0200382:	6bea                	ld	s7,152(sp)
ffffffffc0200384:	6c4a                	ld	s8,144(sp)
ffffffffc0200386:	6caa                	ld	s9,136(sp)
ffffffffc0200388:	6d0a                	ld	s10,128(sp)
ffffffffc020038a:	612d                	addi	sp,sp,224
ffffffffc020038c:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038e:	8526                	mv	a0,s1
ffffffffc0200390:	3c9010ef          	jal	ra,ffffffffc0201f58 <strchr>
ffffffffc0200394:	c901                	beqz	a0,ffffffffc02003a4 <kmonitor+0xf6>
ffffffffc0200396:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc020039a:	00040023          	sb	zero,0(s0)
ffffffffc020039e:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003a0:	d5c9                	beqz	a1,ffffffffc020032a <kmonitor+0x7c>
ffffffffc02003a2:	b7f5                	j	ffffffffc020038e <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc02003a4:	00044783          	lbu	a5,0(s0)
ffffffffc02003a8:	d3c9                	beqz	a5,ffffffffc020032a <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02003aa:	033c8963          	beq	s9,s3,ffffffffc02003dc <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc02003ae:	003c9793          	slli	a5,s9,0x3
ffffffffc02003b2:	0118                	addi	a4,sp,128
ffffffffc02003b4:	97ba                	add	a5,a5,a4
ffffffffc02003b6:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003ba:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003be:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003c0:	e591                	bnez	a1,ffffffffc02003cc <kmonitor+0x11e>
ffffffffc02003c2:	b7b5                	j	ffffffffc020032e <kmonitor+0x80>
ffffffffc02003c4:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003c8:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003ca:	d1a5                	beqz	a1,ffffffffc020032a <kmonitor+0x7c>
ffffffffc02003cc:	8526                	mv	a0,s1
ffffffffc02003ce:	38b010ef          	jal	ra,ffffffffc0201f58 <strchr>
ffffffffc02003d2:	d96d                	beqz	a0,ffffffffc02003c4 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003d4:	00044583          	lbu	a1,0(s0)
ffffffffc02003d8:	d9a9                	beqz	a1,ffffffffc020032a <kmonitor+0x7c>
ffffffffc02003da:	bf55                	j	ffffffffc020038e <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003dc:	45c1                	li	a1,16
ffffffffc02003de:	855a                	mv	a0,s6
ffffffffc02003e0:	d1dff0ef          	jal	ra,ffffffffc02000fc <cprintf>
ffffffffc02003e4:	b7e9                	j	ffffffffc02003ae <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003e6:	6582                	ld	a1,0(sp)
ffffffffc02003e8:	00002517          	auipc	a0,0x2
ffffffffc02003ec:	e4050513          	addi	a0,a0,-448 # ffffffffc0202228 <etext+0x2a8>
ffffffffc02003f0:	d0dff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    return 0;
ffffffffc02003f4:	b715                	j	ffffffffc0200318 <kmonitor+0x6a>

ffffffffc02003f6 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003f6:	00007317          	auipc	t1,0x7
ffffffffc02003fa:	04a30313          	addi	t1,t1,74 # ffffffffc0207440 <is_panic>
ffffffffc02003fe:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200402:	715d                	addi	sp,sp,-80
ffffffffc0200404:	ec06                	sd	ra,24(sp)
ffffffffc0200406:	e822                	sd	s0,16(sp)
ffffffffc0200408:	f436                	sd	a3,40(sp)
ffffffffc020040a:	f83a                	sd	a4,48(sp)
ffffffffc020040c:	fc3e                	sd	a5,56(sp)
ffffffffc020040e:	e0c2                	sd	a6,64(sp)
ffffffffc0200410:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200412:	020e1a63          	bnez	t3,ffffffffc0200446 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200416:	4785                	li	a5,1
ffffffffc0200418:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc020041c:	8432                	mv	s0,a2
ffffffffc020041e:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200420:	862e                	mv	a2,a1
ffffffffc0200422:	85aa                	mv	a1,a0
ffffffffc0200424:	00002517          	auipc	a0,0x2
ffffffffc0200428:	e6450513          	addi	a0,a0,-412 # ffffffffc0202288 <commands+0x48>
    va_start(ap, fmt);
ffffffffc020042c:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020042e:	ccfff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200432:	65a2                	ld	a1,8(sp)
ffffffffc0200434:	8522                	mv	a0,s0
ffffffffc0200436:	ca7ff0ef          	jal	ra,ffffffffc02000dc <vcprintf>
    cprintf("\n");
ffffffffc020043a:	00002517          	auipc	a0,0x2
ffffffffc020043e:	03e50513          	addi	a0,a0,62 # ffffffffc0202478 <commands+0x238>
ffffffffc0200442:	cbbff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200446:	412000ef          	jal	ra,ffffffffc0200858 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020044a:	4501                	li	a0,0
ffffffffc020044c:	e63ff0ef          	jal	ra,ffffffffc02002ae <kmonitor>
    while (1) {
ffffffffc0200450:	bfed                	j	ffffffffc020044a <__panic+0x54>

ffffffffc0200452 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200452:	1141                	addi	sp,sp,-16
ffffffffc0200454:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200456:	02000793          	li	a5,32
ffffffffc020045a:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020045e:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200462:	67e1                	lui	a5,0x18
ffffffffc0200464:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200468:	953e                	add	a0,a0,a5
ffffffffc020046a:	225010ef          	jal	ra,ffffffffc0201e8e <sbi_set_timer>
}
ffffffffc020046e:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200470:	00007797          	auipc	a5,0x7
ffffffffc0200474:	fc07bc23          	sd	zero,-40(a5) # ffffffffc0207448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200478:	00002517          	auipc	a0,0x2
ffffffffc020047c:	e3050513          	addi	a0,a0,-464 # ffffffffc02022a8 <commands+0x68>
}
ffffffffc0200480:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200482:	b9ad                	j	ffffffffc02000fc <cprintf>

ffffffffc0200484 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200484:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200488:	67e1                	lui	a5,0x18
ffffffffc020048a:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020048e:	953e                	add	a0,a0,a5
ffffffffc0200490:	1ff0106f          	j	ffffffffc0201e8e <sbi_set_timer>

ffffffffc0200494 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200494:	8082                	ret

ffffffffc0200496 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200496:	0ff57513          	zext.b	a0,a0
ffffffffc020049a:	1db0106f          	j	ffffffffc0201e74 <sbi_console_putchar>

ffffffffc020049e <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020049e:	20b0106f          	j	ffffffffc0201ea8 <sbi_console_getchar>

ffffffffc02004a2 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02004a2:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02004a4:	00002517          	auipc	a0,0x2
ffffffffc02004a8:	e2450513          	addi	a0,a0,-476 # ffffffffc02022c8 <commands+0x88>
void dtb_init(void) {
ffffffffc02004ac:	fc86                	sd	ra,120(sp)
ffffffffc02004ae:	f8a2                	sd	s0,112(sp)
ffffffffc02004b0:	e8d2                	sd	s4,80(sp)
ffffffffc02004b2:	f4a6                	sd	s1,104(sp)
ffffffffc02004b4:	f0ca                	sd	s2,96(sp)
ffffffffc02004b6:	ecce                	sd	s3,88(sp)
ffffffffc02004b8:	e4d6                	sd	s5,72(sp)
ffffffffc02004ba:	e0da                	sd	s6,64(sp)
ffffffffc02004bc:	fc5e                	sd	s7,56(sp)
ffffffffc02004be:	f862                	sd	s8,48(sp)
ffffffffc02004c0:	f466                	sd	s9,40(sp)
ffffffffc02004c2:	f06a                	sd	s10,32(sp)
ffffffffc02004c4:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004c6:	c37ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004ca:	00007597          	auipc	a1,0x7
ffffffffc02004ce:	b365b583          	ld	a1,-1226(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc02004d2:	00002517          	auipc	a0,0x2
ffffffffc02004d6:	e0650513          	addi	a0,a0,-506 # ffffffffc02022d8 <commands+0x98>
ffffffffc02004da:	c23ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004de:	00007417          	auipc	s0,0x7
ffffffffc02004e2:	b2a40413          	addi	s0,s0,-1238 # ffffffffc0207008 <boot_dtb>
ffffffffc02004e6:	600c                	ld	a1,0(s0)
ffffffffc02004e8:	00002517          	auipc	a0,0x2
ffffffffc02004ec:	e0050513          	addi	a0,a0,-512 # ffffffffc02022e8 <commands+0xa8>
ffffffffc02004f0:	c0dff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004f4:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004f8:	00002517          	auipc	a0,0x2
ffffffffc02004fc:	e0850513          	addi	a0,a0,-504 # ffffffffc0202300 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc0200500:	120a0463          	beqz	s4,ffffffffc0200628 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200504:	57f5                	li	a5,-3
ffffffffc0200506:	07fa                	slli	a5,a5,0x1e
ffffffffc0200508:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020050c:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020050e:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200512:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200514:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200518:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020051c:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200520:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200524:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200528:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052a:	8ec9                	or	a3,a3,a0
ffffffffc020052c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200530:	1b7d                	addi	s6,s6,-1
ffffffffc0200532:	0167f7b3          	and	a5,a5,s6
ffffffffc0200536:	8dd5                	or	a1,a1,a3
ffffffffc0200538:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc020053a:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053e:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200540:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8a4d>
ffffffffc0200544:	10f59163          	bne	a1,a5,ffffffffc0200646 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200548:	471c                	lw	a5,8(a4)
ffffffffc020054a:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc020054c:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020054e:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200552:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200556:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020055a:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020055e:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200562:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200566:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020056a:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020056e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200572:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200576:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200578:	01146433          	or	s0,s0,a7
ffffffffc020057c:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200580:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200584:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200586:	0087979b          	slliw	a5,a5,0x8
ffffffffc020058a:	8c49                	or	s0,s0,a0
ffffffffc020058c:	0166f6b3          	and	a3,a3,s6
ffffffffc0200590:	00ca6a33          	or	s4,s4,a2
ffffffffc0200594:	0167f7b3          	and	a5,a5,s6
ffffffffc0200598:	8c55                	or	s0,s0,a3
ffffffffc020059a:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020059e:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005a0:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005a2:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005a4:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005a8:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005aa:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ac:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc02005b0:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02005b2:	00002917          	auipc	s2,0x2
ffffffffc02005b6:	d9e90913          	addi	s2,s2,-610 # ffffffffc0202350 <commands+0x110>
ffffffffc02005ba:	49bd                	li	s3,15
        switch (token) {
ffffffffc02005bc:	4d91                	li	s11,4
ffffffffc02005be:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005c0:	00002497          	auipc	s1,0x2
ffffffffc02005c4:	d8848493          	addi	s1,s1,-632 # ffffffffc0202348 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005c8:	000a2703          	lw	a4,0(s4)
ffffffffc02005cc:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005d0:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005d4:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005d8:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005dc:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005e0:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005e4:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e6:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ea:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005ee:	8fd5                	or	a5,a5,a3
ffffffffc02005f0:	00eb7733          	and	a4,s6,a4
ffffffffc02005f4:	8fd9                	or	a5,a5,a4
ffffffffc02005f6:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005f8:	09778c63          	beq	a5,s7,ffffffffc0200690 <dtb_init+0x1ee>
ffffffffc02005fc:	00fbea63          	bltu	s7,a5,ffffffffc0200610 <dtb_init+0x16e>
ffffffffc0200600:	07a78663          	beq	a5,s10,ffffffffc020066c <dtb_init+0x1ca>
ffffffffc0200604:	4709                	li	a4,2
ffffffffc0200606:	00e79763          	bne	a5,a4,ffffffffc0200614 <dtb_init+0x172>
ffffffffc020060a:	4c81                	li	s9,0
ffffffffc020060c:	8a56                	mv	s4,s5
ffffffffc020060e:	bf6d                	j	ffffffffc02005c8 <dtb_init+0x126>
ffffffffc0200610:	ffb78ee3          	beq	a5,s11,ffffffffc020060c <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200614:	00002517          	auipc	a0,0x2
ffffffffc0200618:	db450513          	addi	a0,a0,-588 # ffffffffc02023c8 <commands+0x188>
ffffffffc020061c:	ae1ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200620:	00002517          	auipc	a0,0x2
ffffffffc0200624:	de050513          	addi	a0,a0,-544 # ffffffffc0202400 <commands+0x1c0>
}
ffffffffc0200628:	7446                	ld	s0,112(sp)
ffffffffc020062a:	70e6                	ld	ra,120(sp)
ffffffffc020062c:	74a6                	ld	s1,104(sp)
ffffffffc020062e:	7906                	ld	s2,96(sp)
ffffffffc0200630:	69e6                	ld	s3,88(sp)
ffffffffc0200632:	6a46                	ld	s4,80(sp)
ffffffffc0200634:	6aa6                	ld	s5,72(sp)
ffffffffc0200636:	6b06                	ld	s6,64(sp)
ffffffffc0200638:	7be2                	ld	s7,56(sp)
ffffffffc020063a:	7c42                	ld	s8,48(sp)
ffffffffc020063c:	7ca2                	ld	s9,40(sp)
ffffffffc020063e:	7d02                	ld	s10,32(sp)
ffffffffc0200640:	6de2                	ld	s11,24(sp)
ffffffffc0200642:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc0200644:	bc65                	j	ffffffffc02000fc <cprintf>
}
ffffffffc0200646:	7446                	ld	s0,112(sp)
ffffffffc0200648:	70e6                	ld	ra,120(sp)
ffffffffc020064a:	74a6                	ld	s1,104(sp)
ffffffffc020064c:	7906                	ld	s2,96(sp)
ffffffffc020064e:	69e6                	ld	s3,88(sp)
ffffffffc0200650:	6a46                	ld	s4,80(sp)
ffffffffc0200652:	6aa6                	ld	s5,72(sp)
ffffffffc0200654:	6b06                	ld	s6,64(sp)
ffffffffc0200656:	7be2                	ld	s7,56(sp)
ffffffffc0200658:	7c42                	ld	s8,48(sp)
ffffffffc020065a:	7ca2                	ld	s9,40(sp)
ffffffffc020065c:	7d02                	ld	s10,32(sp)
ffffffffc020065e:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200660:	00002517          	auipc	a0,0x2
ffffffffc0200664:	cc050513          	addi	a0,a0,-832 # ffffffffc0202320 <commands+0xe0>
}
ffffffffc0200668:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020066a:	bc49                	j	ffffffffc02000fc <cprintf>
                int name_len = strlen(name);
ffffffffc020066c:	8556                	mv	a0,s5
ffffffffc020066e:	071010ef          	jal	ra,ffffffffc0201ede <strlen>
ffffffffc0200672:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200674:	4619                	li	a2,6
ffffffffc0200676:	85a6                	mv	a1,s1
ffffffffc0200678:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc020067a:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020067c:	0b7010ef          	jal	ra,ffffffffc0201f32 <strncmp>
ffffffffc0200680:	e111                	bnez	a0,ffffffffc0200684 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200682:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200684:	0a91                	addi	s5,s5,4
ffffffffc0200686:	9ad2                	add	s5,s5,s4
ffffffffc0200688:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020068c:	8a56                	mv	s4,s5
ffffffffc020068e:	bf2d                	j	ffffffffc02005c8 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200690:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200694:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200698:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020069c:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a0:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a4:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a8:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006ac:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b0:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b4:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006b8:	00eaeab3          	or	s5,s5,a4
ffffffffc02006bc:	00fb77b3          	and	a5,s6,a5
ffffffffc02006c0:	00faeab3          	or	s5,s5,a5
ffffffffc02006c4:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006c6:	000c9c63          	bnez	s9,ffffffffc02006de <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006ca:	1a82                	slli	s5,s5,0x20
ffffffffc02006cc:	00368793          	addi	a5,a3,3
ffffffffc02006d0:	020ada93          	srli	s5,s5,0x20
ffffffffc02006d4:	9abe                	add	s5,s5,a5
ffffffffc02006d6:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006da:	8a56                	mv	s4,s5
ffffffffc02006dc:	b5f5                	j	ffffffffc02005c8 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006de:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006e2:	85ca                	mv	a1,s2
ffffffffc02006e4:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e6:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ea:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ee:	0187971b          	slliw	a4,a5,0x18
ffffffffc02006f2:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006f6:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006fa:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006fc:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200700:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200704:	8d59                	or	a0,a0,a4
ffffffffc0200706:	00fb77b3          	and	a5,s6,a5
ffffffffc020070a:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020070c:	1502                	slli	a0,a0,0x20
ffffffffc020070e:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200710:	9522                	add	a0,a0,s0
ffffffffc0200712:	003010ef          	jal	ra,ffffffffc0201f14 <strcmp>
ffffffffc0200716:	66a2                	ld	a3,8(sp)
ffffffffc0200718:	f94d                	bnez	a0,ffffffffc02006ca <dtb_init+0x228>
ffffffffc020071a:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006ca <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020071e:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200722:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200726:	00002517          	auipc	a0,0x2
ffffffffc020072a:	c3250513          	addi	a0,a0,-974 # ffffffffc0202358 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc020072e:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200732:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200736:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073a:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020073e:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200742:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200746:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020074a:	0187d693          	srli	a3,a5,0x18
ffffffffc020074e:	01861f1b          	slliw	t5,a2,0x18
ffffffffc0200752:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200756:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020075a:	0106561b          	srliw	a2,a2,0x10
ffffffffc020075e:	010f6f33          	or	t5,t5,a6
ffffffffc0200762:	0187529b          	srliw	t0,a4,0x18
ffffffffc0200766:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020076a:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020076e:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200772:	0186f6b3          	and	a3,a3,s8
ffffffffc0200776:	01859e1b          	slliw	t3,a1,0x18
ffffffffc020077a:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020077e:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200782:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200786:	8361                	srli	a4,a4,0x18
ffffffffc0200788:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020078c:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200790:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200794:	00cb7633          	and	a2,s6,a2
ffffffffc0200798:	0088181b          	slliw	a6,a6,0x8
ffffffffc020079c:	0085959b          	slliw	a1,a1,0x8
ffffffffc02007a0:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007a4:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a8:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ac:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007b0:	0088989b          	slliw	a7,a7,0x8
ffffffffc02007b4:	011b78b3          	and	a7,s6,a7
ffffffffc02007b8:	005eeeb3          	or	t4,t4,t0
ffffffffc02007bc:	00c6e733          	or	a4,a3,a2
ffffffffc02007c0:	006c6c33          	or	s8,s8,t1
ffffffffc02007c4:	010b76b3          	and	a3,s6,a6
ffffffffc02007c8:	00bb7b33          	and	s6,s6,a1
ffffffffc02007cc:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007d0:	016c6b33          	or	s6,s8,s6
ffffffffc02007d4:	01146433          	or	s0,s0,a7
ffffffffc02007d8:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007da:	1702                	slli	a4,a4,0x20
ffffffffc02007dc:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007de:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007e0:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007e2:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007e4:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007e8:	0167eb33          	or	s6,a5,s6
ffffffffc02007ec:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007ee:	90fff0ef          	jal	ra,ffffffffc02000fc <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02007f2:	85a2                	mv	a1,s0
ffffffffc02007f4:	00002517          	auipc	a0,0x2
ffffffffc02007f8:	b8450513          	addi	a0,a0,-1148 # ffffffffc0202378 <commands+0x138>
ffffffffc02007fc:	901ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200800:	014b5613          	srli	a2,s6,0x14
ffffffffc0200804:	85da                	mv	a1,s6
ffffffffc0200806:	00002517          	auipc	a0,0x2
ffffffffc020080a:	b8a50513          	addi	a0,a0,-1142 # ffffffffc0202390 <commands+0x150>
ffffffffc020080e:	8efff0ef          	jal	ra,ffffffffc02000fc <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200812:	008b05b3          	add	a1,s6,s0
ffffffffc0200816:	15fd                	addi	a1,a1,-1
ffffffffc0200818:	00002517          	auipc	a0,0x2
ffffffffc020081c:	b9850513          	addi	a0,a0,-1128 # ffffffffc02023b0 <commands+0x170>
ffffffffc0200820:	8ddff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200824:	00002517          	auipc	a0,0x2
ffffffffc0200828:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0202400 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc020082c:	00007797          	auipc	a5,0x7
ffffffffc0200830:	c287b223          	sd	s0,-988(a5) # ffffffffc0207450 <memory_base>
        memory_size = mem_size;
ffffffffc0200834:	00007797          	auipc	a5,0x7
ffffffffc0200838:	c367b223          	sd	s6,-988(a5) # ffffffffc0207458 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc020083c:	b3f5                	j	ffffffffc0200628 <dtb_init+0x186>

ffffffffc020083e <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020083e:	00007517          	auipc	a0,0x7
ffffffffc0200842:	c1253503          	ld	a0,-1006(a0) # ffffffffc0207450 <memory_base>
ffffffffc0200846:	8082                	ret

ffffffffc0200848 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc0200848:	00007517          	auipc	a0,0x7
ffffffffc020084c:	c1053503          	ld	a0,-1008(a0) # ffffffffc0207458 <memory_size>
ffffffffc0200850:	8082                	ret

ffffffffc0200852 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200852:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200856:	8082                	ret

ffffffffc0200858 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200858:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020085c:	8082                	ret

ffffffffc020085e <exception_handler.part.0>:
            print_trapframe(tf);
            break;
    }
}

void exception_handler(struct trapframe *tf) {
ffffffffc020085e:	7179                	addi	sp,sp,-48
ffffffffc0200860:	e84a                	sd	s2,16(sp)
ffffffffc0200862:	892a                	mv	s2,a0
            */
            break;
       case CAUSE_BREAKPOINT:
            // 断点异常的处理
            // 这里实现了一个具备状态观测和交互式控制的初级内核调试器。
            cprintf("Exception type: breakpoint\n");
ffffffffc0200864:	00002517          	auipc	a0,0x2
ffffffffc0200868:	bb450513          	addi	a0,a0,-1100 # ffffffffc0202418 <commands+0x1d8>
void exception_handler(struct trapframe *tf) {
ffffffffc020086c:	f406                	sd	ra,40(sp)
ffffffffc020086e:	f022                	sd	s0,32(sp)
ffffffffc0200870:	ec26                	sd	s1,24(sp)
ffffffffc0200872:	e44e                	sd	s3,8(sp)
ffffffffc0200874:	e052                	sd	s4,0(sp)
            cprintf("Exception type: breakpoint\n");
ffffffffc0200876:	887ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
            cprintf("ebreak caught at 0x%016lx\n", tf->epc);
ffffffffc020087a:	10893583          	ld	a1,264(s2)
ffffffffc020087e:	00002517          	auipc	a0,0x2
ffffffffc0200882:	bba50513          	addi	a0,a0,-1094 # ffffffffc0202438 <commands+0x1f8>

            // 功能 1: 状态观测 - 侦察函数内部状态 (参数和栈)。
            cprintf("\n --- Current Function State ---\n");
            cprintf("   Arguments (a0-a1): 0x%lx, 0x%lx\n", tf->gpr.a0, tf->gpr.a1);
            cprintf("   Stack Snapshot (around sp=0x%lx):\n", tf->gpr.sp);
            uintptr_t *sp = (uintptr_t *)tf->gpr.sp;
ffffffffc0200886:	4401                	li	s0,0
            cprintf("ebreak caught at 0x%016lx\n", tf->epc);
ffffffffc0200888:	875ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
            cprintf("\n --- Current Function State ---\n");
ffffffffc020088c:	00002517          	auipc	a0,0x2
ffffffffc0200890:	bcc50513          	addi	a0,a0,-1076 # ffffffffc0202458 <commands+0x218>
ffffffffc0200894:	869ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
            cprintf("   Arguments (a0-a1): 0x%lx, 0x%lx\n", tf->gpr.a0, tf->gpr.a1);
ffffffffc0200898:	05893603          	ld	a2,88(s2)
ffffffffc020089c:	05093583          	ld	a1,80(s2)
ffffffffc02008a0:	00002517          	auipc	a0,0x2
ffffffffc02008a4:	be050513          	addi	a0,a0,-1056 # ffffffffc0202480 <commands+0x240>
            for (int i = 0; i < 4; i++) {
                cprintf("     sp+%d: 0x%016lx\n", i * 8, *(sp + i));
ffffffffc02008a8:	00002a17          	auipc	s4,0x2
ffffffffc02008ac:	c28a0a13          	addi	s4,s4,-984 # ffffffffc02024d0 <commands+0x290>
            cprintf("   Arguments (a0-a1): 0x%lx, 0x%lx\n", tf->gpr.a0, tf->gpr.a1);
ffffffffc02008b0:	84dff0ef          	jal	ra,ffffffffc02000fc <cprintf>
            cprintf("   Stack Snapshot (around sp=0x%lx):\n", tf->gpr.sp);
ffffffffc02008b4:	01093583          	ld	a1,16(s2)
ffffffffc02008b8:	00002517          	auipc	a0,0x2
ffffffffc02008bc:	bf050513          	addi	a0,a0,-1040 # ffffffffc02024a8 <commands+0x268>
            for (int i = 0; i < 4; i++) {
ffffffffc02008c0:	02000993          	li	s3,32
            cprintf("   Stack Snapshot (around sp=0x%lx):\n", tf->gpr.sp);
ffffffffc02008c4:	839ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
            uintptr_t *sp = (uintptr_t *)tf->gpr.sp;
ffffffffc02008c8:	01093483          	ld	s1,16(s2)
                cprintf("     sp+%d: 0x%016lx\n", i * 8, *(sp + i));
ffffffffc02008cc:	6090                	ld	a2,0(s1)
ffffffffc02008ce:	85a2                	mv	a1,s0
ffffffffc02008d0:	8552                	mv	a0,s4
            for (int i = 0; i < 4; i++) {
ffffffffc02008d2:	2421                	addiw	s0,s0,8
                cprintf("     sp+%d: 0x%016lx\n", i * 8, *(sp + i));
ffffffffc02008d4:	829ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
            for (int i = 0; i < 4; i++) {
ffffffffc02008d8:	04a1                	addi	s1,s1,8
ffffffffc02008da:	ff3419e3          	bne	s0,s3,ffffffffc02008cc <exception_handler.part.0+0x6e>
            }

            // 功能 2: 状态观测 - 侦察系统全局状态。
            cprintf("\n --- Global State ---\n");
ffffffffc02008de:	00002517          	auipc	a0,0x2
ffffffffc02008e2:	c0a50513          	addi	a0,a0,-1014 # ffffffffc02024e8 <commands+0x2a8>
ffffffffc02008e6:	817ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
            cprintf("   Current 'ticks' value: %d\n", ticks);
ffffffffc02008ea:	00007597          	auipc	a1,0x7
ffffffffc02008ee:	b5e5b583          	ld	a1,-1186(a1) # ffffffffc0207448 <ticks>
ffffffffc02008f2:	00002517          	auipc	a0,0x2
ffffffffc02008f6:	c0e50513          	addi	a0,a0,-1010 # ffffffffc0202500 <commands+0x2c0>
ffffffffc02008fa:	803ff0ef          	jal	ra,ffffffffc02000fc <cprintf>

            // 功能 3: 交互式控制 - 等待用户输入 'c' 以继续。
            cprintf("\n >> Type 'c' and press Enter to continue...\n");
ffffffffc02008fe:	00002517          	auipc	a0,0x2
ffffffffc0200902:	c2250513          	addi	a0,a0,-990 # ffffffffc0202520 <commands+0x2e0>
ffffffffc0200906:	ff6ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
            int c;
            while ((c = cons_getc()) != 'c') {
ffffffffc020090a:	06300413          	li	s0,99
ffffffffc020090e:	b91ff0ef          	jal	ra,ffffffffc020049e <cons_getc>
ffffffffc0200912:	fe851ee3          	bne	a0,s0,ffffffffc020090e <exception_handler.part.0+0xb0>
                // 这是一个“忙等待”循环，会持续检查控制台输入，直到收到 'c'。
            }
            cprintf("  >> 'c' received. Resuming execution.\n");
ffffffffc0200916:	00002517          	auipc	a0,0x2
ffffffffc020091a:	c3a50513          	addi	a0,a0,-966 # ffffffffc0202550 <commands+0x310>
ffffffffc020091e:	fdeff0ef          	jal	ra,ffffffffc02000fc <cprintf>

            // 功能 4: 健壮地恢复执行流。
            // 从 epc 指向的地址读取指令的前 16 位。
            uint16_t instruction = *(uint16_t *)tf->epc;
ffffffffc0200922:	10893703          	ld	a4,264(s2)
            // 通过检查指令编码的最低两位来动态判断指令长度，以确保能正确跳过 ebreak 指令。
            if ((instruction & 0x3) != 0x3) {
ffffffffc0200926:	468d                	li	a3,3
ffffffffc0200928:	00075783          	lhu	a5,0(a4)
                // 这是一个 16-bit 的压缩指令。
                tf->epc += 2;
            } else {
                // 这是一个 32-bit 的标准指令。
                tf->epc += 4;
ffffffffc020092c:	00470593          	addi	a1,a4,4
            if ((instruction & 0x3) != 0x3) {
ffffffffc0200930:	8b8d                	andi	a5,a5,3
ffffffffc0200932:	00d78463          	beq	a5,a3,ffffffffc020093a <exception_handler.part.0+0xdc>
                tf->epc += 2;
ffffffffc0200936:	00270593          	addi	a1,a4,2
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc020093a:	7402                	ld	s0,32(sp)
ffffffffc020093c:	70a2                	ld	ra,40(sp)
ffffffffc020093e:	64e2                	ld	s1,24(sp)
ffffffffc0200940:	69a2                	ld	s3,8(sp)
ffffffffc0200942:	6a02                	ld	s4,0(sp)
ffffffffc0200944:	10b93423          	sd	a1,264(s2)
ffffffffc0200948:	6942                	ld	s2,16(sp)
            cprintf("restore at 0x%016lx\n", tf->epc);
ffffffffc020094a:	00002517          	auipc	a0,0x2
ffffffffc020094e:	c2e50513          	addi	a0,a0,-978 # ffffffffc0202578 <commands+0x338>
}
ffffffffc0200952:	6145                	addi	sp,sp,48
            cprintf("restore at 0x%016lx\n", tf->epc);
ffffffffc0200954:	fa8ff06f          	j	ffffffffc02000fc <cprintf>

ffffffffc0200958 <idt_init>:
    write_csr(sscratch, 0);
ffffffffc0200958:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc020095c:	00000797          	auipc	a5,0x0
ffffffffc0200960:	33478793          	addi	a5,a5,820 # ffffffffc0200c90 <__alltraps>
ffffffffc0200964:	10579073          	csrw	stvec,a5
}
ffffffffc0200968:	8082                	ret

ffffffffc020096a <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020096a:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020096c:	1141                	addi	sp,sp,-16
ffffffffc020096e:	e022                	sd	s0,0(sp)
ffffffffc0200970:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200972:	00002517          	auipc	a0,0x2
ffffffffc0200976:	c1e50513          	addi	a0,a0,-994 # ffffffffc0202590 <commands+0x350>
void print_regs(struct pushregs *gpr) {
ffffffffc020097a:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020097c:	f80ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200980:	640c                	ld	a1,8(s0)
ffffffffc0200982:	00002517          	auipc	a0,0x2
ffffffffc0200986:	c2650513          	addi	a0,a0,-986 # ffffffffc02025a8 <commands+0x368>
ffffffffc020098a:	f72ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020098e:	680c                	ld	a1,16(s0)
ffffffffc0200990:	00002517          	auipc	a0,0x2
ffffffffc0200994:	c3050513          	addi	a0,a0,-976 # ffffffffc02025c0 <commands+0x380>
ffffffffc0200998:	f64ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020099c:	6c0c                	ld	a1,24(s0)
ffffffffc020099e:	00002517          	auipc	a0,0x2
ffffffffc02009a2:	c3a50513          	addi	a0,a0,-966 # ffffffffc02025d8 <commands+0x398>
ffffffffc02009a6:	f56ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02009aa:	700c                	ld	a1,32(s0)
ffffffffc02009ac:	00002517          	auipc	a0,0x2
ffffffffc02009b0:	c4450513          	addi	a0,a0,-956 # ffffffffc02025f0 <commands+0x3b0>
ffffffffc02009b4:	f48ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02009b8:	740c                	ld	a1,40(s0)
ffffffffc02009ba:	00002517          	auipc	a0,0x2
ffffffffc02009be:	c4e50513          	addi	a0,a0,-946 # ffffffffc0202608 <commands+0x3c8>
ffffffffc02009c2:	f3aff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02009c6:	780c                	ld	a1,48(s0)
ffffffffc02009c8:	00002517          	auipc	a0,0x2
ffffffffc02009cc:	c5850513          	addi	a0,a0,-936 # ffffffffc0202620 <commands+0x3e0>
ffffffffc02009d0:	f2cff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02009d4:	7c0c                	ld	a1,56(s0)
ffffffffc02009d6:	00002517          	auipc	a0,0x2
ffffffffc02009da:	c6250513          	addi	a0,a0,-926 # ffffffffc0202638 <commands+0x3f8>
ffffffffc02009de:	f1eff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02009e2:	602c                	ld	a1,64(s0)
ffffffffc02009e4:	00002517          	auipc	a0,0x2
ffffffffc02009e8:	c6c50513          	addi	a0,a0,-916 # ffffffffc0202650 <commands+0x410>
ffffffffc02009ec:	f10ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009f0:	642c                	ld	a1,72(s0)
ffffffffc02009f2:	00002517          	auipc	a0,0x2
ffffffffc02009f6:	c7650513          	addi	a0,a0,-906 # ffffffffc0202668 <commands+0x428>
ffffffffc02009fa:	f02ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009fe:	682c                	ld	a1,80(s0)
ffffffffc0200a00:	00002517          	auipc	a0,0x2
ffffffffc0200a04:	c8050513          	addi	a0,a0,-896 # ffffffffc0202680 <commands+0x440>
ffffffffc0200a08:	ef4ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a0c:	6c2c                	ld	a1,88(s0)
ffffffffc0200a0e:	00002517          	auipc	a0,0x2
ffffffffc0200a12:	c8a50513          	addi	a0,a0,-886 # ffffffffc0202698 <commands+0x458>
ffffffffc0200a16:	ee6ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a1a:	702c                	ld	a1,96(s0)
ffffffffc0200a1c:	00002517          	auipc	a0,0x2
ffffffffc0200a20:	c9450513          	addi	a0,a0,-876 # ffffffffc02026b0 <commands+0x470>
ffffffffc0200a24:	ed8ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a28:	742c                	ld	a1,104(s0)
ffffffffc0200a2a:	00002517          	auipc	a0,0x2
ffffffffc0200a2e:	c9e50513          	addi	a0,a0,-866 # ffffffffc02026c8 <commands+0x488>
ffffffffc0200a32:	ecaff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a36:	782c                	ld	a1,112(s0)
ffffffffc0200a38:	00002517          	auipc	a0,0x2
ffffffffc0200a3c:	ca850513          	addi	a0,a0,-856 # ffffffffc02026e0 <commands+0x4a0>
ffffffffc0200a40:	ebcff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a44:	7c2c                	ld	a1,120(s0)
ffffffffc0200a46:	00002517          	auipc	a0,0x2
ffffffffc0200a4a:	cb250513          	addi	a0,a0,-846 # ffffffffc02026f8 <commands+0x4b8>
ffffffffc0200a4e:	eaeff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a52:	604c                	ld	a1,128(s0)
ffffffffc0200a54:	00002517          	auipc	a0,0x2
ffffffffc0200a58:	cbc50513          	addi	a0,a0,-836 # ffffffffc0202710 <commands+0x4d0>
ffffffffc0200a5c:	ea0ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a60:	644c                	ld	a1,136(s0)
ffffffffc0200a62:	00002517          	auipc	a0,0x2
ffffffffc0200a66:	cc650513          	addi	a0,a0,-826 # ffffffffc0202728 <commands+0x4e8>
ffffffffc0200a6a:	e92ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a6e:	684c                	ld	a1,144(s0)
ffffffffc0200a70:	00002517          	auipc	a0,0x2
ffffffffc0200a74:	cd050513          	addi	a0,a0,-816 # ffffffffc0202740 <commands+0x500>
ffffffffc0200a78:	e84ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a7c:	6c4c                	ld	a1,152(s0)
ffffffffc0200a7e:	00002517          	auipc	a0,0x2
ffffffffc0200a82:	cda50513          	addi	a0,a0,-806 # ffffffffc0202758 <commands+0x518>
ffffffffc0200a86:	e76ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a8a:	704c                	ld	a1,160(s0)
ffffffffc0200a8c:	00002517          	auipc	a0,0x2
ffffffffc0200a90:	ce450513          	addi	a0,a0,-796 # ffffffffc0202770 <commands+0x530>
ffffffffc0200a94:	e68ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a98:	744c                	ld	a1,168(s0)
ffffffffc0200a9a:	00002517          	auipc	a0,0x2
ffffffffc0200a9e:	cee50513          	addi	a0,a0,-786 # ffffffffc0202788 <commands+0x548>
ffffffffc0200aa2:	e5aff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200aa6:	784c                	ld	a1,176(s0)
ffffffffc0200aa8:	00002517          	auipc	a0,0x2
ffffffffc0200aac:	cf850513          	addi	a0,a0,-776 # ffffffffc02027a0 <commands+0x560>
ffffffffc0200ab0:	e4cff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200ab4:	7c4c                	ld	a1,184(s0)
ffffffffc0200ab6:	00002517          	auipc	a0,0x2
ffffffffc0200aba:	d0250513          	addi	a0,a0,-766 # ffffffffc02027b8 <commands+0x578>
ffffffffc0200abe:	e3eff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200ac2:	606c                	ld	a1,192(s0)
ffffffffc0200ac4:	00002517          	auipc	a0,0x2
ffffffffc0200ac8:	d0c50513          	addi	a0,a0,-756 # ffffffffc02027d0 <commands+0x590>
ffffffffc0200acc:	e30ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200ad0:	646c                	ld	a1,200(s0)
ffffffffc0200ad2:	00002517          	auipc	a0,0x2
ffffffffc0200ad6:	d1650513          	addi	a0,a0,-746 # ffffffffc02027e8 <commands+0x5a8>
ffffffffc0200ada:	e22ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200ade:	686c                	ld	a1,208(s0)
ffffffffc0200ae0:	00002517          	auipc	a0,0x2
ffffffffc0200ae4:	d2050513          	addi	a0,a0,-736 # ffffffffc0202800 <commands+0x5c0>
ffffffffc0200ae8:	e14ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200aec:	6c6c                	ld	a1,216(s0)
ffffffffc0200aee:	00002517          	auipc	a0,0x2
ffffffffc0200af2:	d2a50513          	addi	a0,a0,-726 # ffffffffc0202818 <commands+0x5d8>
ffffffffc0200af6:	e06ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200afa:	706c                	ld	a1,224(s0)
ffffffffc0200afc:	00002517          	auipc	a0,0x2
ffffffffc0200b00:	d3450513          	addi	a0,a0,-716 # ffffffffc0202830 <commands+0x5f0>
ffffffffc0200b04:	df8ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b08:	746c                	ld	a1,232(s0)
ffffffffc0200b0a:	00002517          	auipc	a0,0x2
ffffffffc0200b0e:	d3e50513          	addi	a0,a0,-706 # ffffffffc0202848 <commands+0x608>
ffffffffc0200b12:	deaff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b16:	786c                	ld	a1,240(s0)
ffffffffc0200b18:	00002517          	auipc	a0,0x2
ffffffffc0200b1c:	d4850513          	addi	a0,a0,-696 # ffffffffc0202860 <commands+0x620>
ffffffffc0200b20:	ddcff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b24:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b26:	6402                	ld	s0,0(sp)
ffffffffc0200b28:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b2a:	00002517          	auipc	a0,0x2
ffffffffc0200b2e:	d4e50513          	addi	a0,a0,-690 # ffffffffc0202878 <commands+0x638>
}
ffffffffc0200b32:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b34:	dc8ff06f          	j	ffffffffc02000fc <cprintf>

ffffffffc0200b38 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200b38:	1141                	addi	sp,sp,-16
ffffffffc0200b3a:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b3c:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200b3e:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b40:	00002517          	auipc	a0,0x2
ffffffffc0200b44:	d5050513          	addi	a0,a0,-688 # ffffffffc0202890 <commands+0x650>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200b48:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b4a:	db2ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b4e:	8522                	mv	a0,s0
ffffffffc0200b50:	e1bff0ef          	jal	ra,ffffffffc020096a <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b54:	10043583          	ld	a1,256(s0)
ffffffffc0200b58:	00002517          	auipc	a0,0x2
ffffffffc0200b5c:	d5050513          	addi	a0,a0,-688 # ffffffffc02028a8 <commands+0x668>
ffffffffc0200b60:	d9cff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b64:	10843583          	ld	a1,264(s0)
ffffffffc0200b68:	00002517          	auipc	a0,0x2
ffffffffc0200b6c:	d5850513          	addi	a0,a0,-680 # ffffffffc02028c0 <commands+0x680>
ffffffffc0200b70:	d8cff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200b74:	11043583          	ld	a1,272(s0)
ffffffffc0200b78:	00002517          	auipc	a0,0x2
ffffffffc0200b7c:	d6050513          	addi	a0,a0,-672 # ffffffffc02028d8 <commands+0x698>
ffffffffc0200b80:	d7cff0ef          	jal	ra,ffffffffc02000fc <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b84:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b88:	6402                	ld	s0,0(sp)
ffffffffc0200b8a:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b8c:	00002517          	auipc	a0,0x2
ffffffffc0200b90:	d6450513          	addi	a0,a0,-668 # ffffffffc02028f0 <commands+0x6b0>
}
ffffffffc0200b94:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b96:	d66ff06f          	j	ffffffffc02000fc <cprintf>

ffffffffc0200b9a <interrupt_handler>:
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200b9a:	11853783          	ld	a5,280(a0)
ffffffffc0200b9e:	472d                	li	a4,11
ffffffffc0200ba0:	0786                	slli	a5,a5,0x1
ffffffffc0200ba2:	8385                	srli	a5,a5,0x1
ffffffffc0200ba4:	08f76a63          	bltu	a4,a5,ffffffffc0200c38 <interrupt_handler+0x9e>
ffffffffc0200ba8:	00002717          	auipc	a4,0x2
ffffffffc0200bac:	e2870713          	addi	a4,a4,-472 # ffffffffc02029d0 <commands+0x790>
ffffffffc0200bb0:	078a                	slli	a5,a5,0x2
ffffffffc0200bb2:	97ba                	add	a5,a5,a4
ffffffffc0200bb4:	439c                	lw	a5,0(a5)
ffffffffc0200bb6:	97ba                	add	a5,a5,a4
ffffffffc0200bb8:	8782                	jr	a5
            cprintf("Machine software interrupt\n");
ffffffffc0200bba:	00002517          	auipc	a0,0x2
ffffffffc0200bbe:	dae50513          	addi	a0,a0,-594 # ffffffffc0202968 <commands+0x728>
ffffffffc0200bc2:	d3aff06f          	j	ffffffffc02000fc <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200bc6:	00002517          	auipc	a0,0x2
ffffffffc0200bca:	d8250513          	addi	a0,a0,-638 # ffffffffc0202948 <commands+0x708>
ffffffffc0200bce:	d2eff06f          	j	ffffffffc02000fc <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200bd2:	00002517          	auipc	a0,0x2
ffffffffc0200bd6:	d3650513          	addi	a0,a0,-714 # ffffffffc0202908 <commands+0x6c8>
ffffffffc0200bda:	d22ff06f          	j	ffffffffc02000fc <cprintf>
            cprintf("User Timer interrupt\n");
ffffffffc0200bde:	00002517          	auipc	a0,0x2
ffffffffc0200be2:	daa50513          	addi	a0,a0,-598 # ffffffffc0202988 <commands+0x748>
ffffffffc0200be6:	d16ff06f          	j	ffffffffc02000fc <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200bea:	1141                	addi	sp,sp,-16
ffffffffc0200bec:	e406                	sd	ra,8(sp)
            clock_set_next_event();
ffffffffc0200bee:	897ff0ef          	jal	ra,ffffffffc0200484 <clock_set_next_event>
            ticks++;
ffffffffc0200bf2:	00007797          	auipc	a5,0x7
ffffffffc0200bf6:	85678793          	addi	a5,a5,-1962 # ffffffffc0207448 <ticks>
ffffffffc0200bfa:	6398                	ld	a4,0(a5)
ffffffffc0200bfc:	0705                	addi	a4,a4,1
ffffffffc0200bfe:	e398                	sd	a4,0(a5)
            if (ticks % TICK_NUM == 0) {
ffffffffc0200c00:	639c                	ld	a5,0(a5)
ffffffffc0200c02:	06400713          	li	a4,100
ffffffffc0200c06:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200c0a:	cb85                	beqz	a5,ffffffffc0200c3a <interrupt_handler+0xa0>
            if (print_count == PRINT_TICK_NUM) {
ffffffffc0200c0c:	00007797          	auipc	a5,0x7
ffffffffc0200c10:	8547b783          	ld	a5,-1964(a5) # ffffffffc0207460 <print_count>
ffffffffc0200c14:	4729                	li	a4,10
ffffffffc0200c16:	04e78263          	beq	a5,a4,ffffffffc0200c5a <interrupt_handler+0xc0>
}
ffffffffc0200c1a:	60a2                	ld	ra,8(sp)
ffffffffc0200c1c:	0141                	addi	sp,sp,16
ffffffffc0200c1e:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200c20:	00002517          	auipc	a0,0x2
ffffffffc0200c24:	d9050513          	addi	a0,a0,-624 # ffffffffc02029b0 <commands+0x770>
ffffffffc0200c28:	cd4ff06f          	j	ffffffffc02000fc <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200c2c:	00002517          	auipc	a0,0x2
ffffffffc0200c30:	cfc50513          	addi	a0,a0,-772 # ffffffffc0202928 <commands+0x6e8>
ffffffffc0200c34:	cc8ff06f          	j	ffffffffc02000fc <cprintf>
            print_trapframe(tf);
ffffffffc0200c38:	b701                	j	ffffffffc0200b38 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c3a:	06400593          	li	a1,100
ffffffffc0200c3e:	00002517          	auipc	a0,0x2
ffffffffc0200c42:	d6250513          	addi	a0,a0,-670 # ffffffffc02029a0 <commands+0x760>
ffffffffc0200c46:	cb6ff0ef          	jal	ra,ffffffffc02000fc <cprintf>
                print_count++;
ffffffffc0200c4a:	00007717          	auipc	a4,0x7
ffffffffc0200c4e:	81670713          	addi	a4,a4,-2026 # ffffffffc0207460 <print_count>
ffffffffc0200c52:	631c                	ld	a5,0(a4)
ffffffffc0200c54:	0785                	addi	a5,a5,1
ffffffffc0200c56:	e31c                	sd	a5,0(a4)
ffffffffc0200c58:	bf75                	j	ffffffffc0200c14 <interrupt_handler+0x7a>
}
ffffffffc0200c5a:	60a2                	ld	ra,8(sp)
ffffffffc0200c5c:	0141                	addi	sp,sp,16
                sbi_shutdown();
ffffffffc0200c5e:	2660106f          	j	ffffffffc0201ec4 <sbi_shutdown>

ffffffffc0200c62 <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c62:	11853783          	ld	a5,280(a0)
 * trap - handles or dispatches an exception/interrupt. if and when trap()
 * returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
ffffffffc0200c66:	872a                	mv	a4,a0
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c68:	0007cf63          	bltz	a5,ffffffffc0200c86 <trap+0x24>
    switch (tf->cause) {
ffffffffc0200c6c:	468d                	li	a3,3
ffffffffc0200c6e:	00d78f63          	beq	a5,a3,ffffffffc0200c8c <trap+0x2a>
ffffffffc0200c72:	00f6f763          	bgeu	a3,a5,ffffffffc0200c80 <trap+0x1e>
ffffffffc0200c76:	17f1                	addi	a5,a5,-4
ffffffffc0200c78:	469d                	li	a3,7
ffffffffc0200c7a:	00f6e763          	bltu	a3,a5,ffffffffc0200c88 <trap+0x26>
ffffffffc0200c7e:	8082                	ret
ffffffffc0200c80:	00d78463          	beq	a5,a3,ffffffffc0200c88 <trap+0x26>
ffffffffc0200c84:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200c86:	bf11                	j	ffffffffc0200b9a <interrupt_handler>
            print_trapframe(tf);
ffffffffc0200c88:	853a                	mv	a0,a4
ffffffffc0200c8a:	b57d                	j	ffffffffc0200b38 <print_trapframe>
ffffffffc0200c8c:	bec9                	j	ffffffffc020085e <exception_handler.part.0>
	...

ffffffffc0200c90 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200c90:	14011073          	csrw	sscratch,sp
ffffffffc0200c94:	712d                	addi	sp,sp,-288
ffffffffc0200c96:	e002                	sd	zero,0(sp)
ffffffffc0200c98:	e406                	sd	ra,8(sp)
ffffffffc0200c9a:	ec0e                	sd	gp,24(sp)
ffffffffc0200c9c:	f012                	sd	tp,32(sp)
ffffffffc0200c9e:	f416                	sd	t0,40(sp)
ffffffffc0200ca0:	f81a                	sd	t1,48(sp)
ffffffffc0200ca2:	fc1e                	sd	t2,56(sp)
ffffffffc0200ca4:	e0a2                	sd	s0,64(sp)
ffffffffc0200ca6:	e4a6                	sd	s1,72(sp)
ffffffffc0200ca8:	e8aa                	sd	a0,80(sp)
ffffffffc0200caa:	ecae                	sd	a1,88(sp)
ffffffffc0200cac:	f0b2                	sd	a2,96(sp)
ffffffffc0200cae:	f4b6                	sd	a3,104(sp)
ffffffffc0200cb0:	f8ba                	sd	a4,112(sp)
ffffffffc0200cb2:	fcbe                	sd	a5,120(sp)
ffffffffc0200cb4:	e142                	sd	a6,128(sp)
ffffffffc0200cb6:	e546                	sd	a7,136(sp)
ffffffffc0200cb8:	e94a                	sd	s2,144(sp)
ffffffffc0200cba:	ed4e                	sd	s3,152(sp)
ffffffffc0200cbc:	f152                	sd	s4,160(sp)
ffffffffc0200cbe:	f556                	sd	s5,168(sp)
ffffffffc0200cc0:	f95a                	sd	s6,176(sp)
ffffffffc0200cc2:	fd5e                	sd	s7,184(sp)
ffffffffc0200cc4:	e1e2                	sd	s8,192(sp)
ffffffffc0200cc6:	e5e6                	sd	s9,200(sp)
ffffffffc0200cc8:	e9ea                	sd	s10,208(sp)
ffffffffc0200cca:	edee                	sd	s11,216(sp)
ffffffffc0200ccc:	f1f2                	sd	t3,224(sp)
ffffffffc0200cce:	f5f6                	sd	t4,232(sp)
ffffffffc0200cd0:	f9fa                	sd	t5,240(sp)
ffffffffc0200cd2:	fdfe                	sd	t6,248(sp)
ffffffffc0200cd4:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200cd8:	100024f3          	csrr	s1,sstatus
ffffffffc0200cdc:	14102973          	csrr	s2,sepc
ffffffffc0200ce0:	143029f3          	csrr	s3,stval
ffffffffc0200ce4:	14202a73          	csrr	s4,scause
ffffffffc0200ce8:	e822                	sd	s0,16(sp)
ffffffffc0200cea:	e226                	sd	s1,256(sp)
ffffffffc0200cec:	e64a                	sd	s2,264(sp)
ffffffffc0200cee:	ea4e                	sd	s3,272(sp)
ffffffffc0200cf0:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200cf2:	850a                	mv	a0,sp
    jal trap
ffffffffc0200cf4:	f6fff0ef          	jal	ra,ffffffffc0200c62 <trap>

ffffffffc0200cf8 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200cf8:	6492                	ld	s1,256(sp)
ffffffffc0200cfa:	6932                	ld	s2,264(sp)
ffffffffc0200cfc:	10049073          	csrw	sstatus,s1
ffffffffc0200d00:	14191073          	csrw	sepc,s2
ffffffffc0200d04:	60a2                	ld	ra,8(sp)
ffffffffc0200d06:	61e2                	ld	gp,24(sp)
ffffffffc0200d08:	7202                	ld	tp,32(sp)
ffffffffc0200d0a:	72a2                	ld	t0,40(sp)
ffffffffc0200d0c:	7342                	ld	t1,48(sp)
ffffffffc0200d0e:	73e2                	ld	t2,56(sp)
ffffffffc0200d10:	6406                	ld	s0,64(sp)
ffffffffc0200d12:	64a6                	ld	s1,72(sp)
ffffffffc0200d14:	6546                	ld	a0,80(sp)
ffffffffc0200d16:	65e6                	ld	a1,88(sp)
ffffffffc0200d18:	7606                	ld	a2,96(sp)
ffffffffc0200d1a:	76a6                	ld	a3,104(sp)
ffffffffc0200d1c:	7746                	ld	a4,112(sp)
ffffffffc0200d1e:	77e6                	ld	a5,120(sp)
ffffffffc0200d20:	680a                	ld	a6,128(sp)
ffffffffc0200d22:	68aa                	ld	a7,136(sp)
ffffffffc0200d24:	694a                	ld	s2,144(sp)
ffffffffc0200d26:	69ea                	ld	s3,152(sp)
ffffffffc0200d28:	7a0a                	ld	s4,160(sp)
ffffffffc0200d2a:	7aaa                	ld	s5,168(sp)
ffffffffc0200d2c:	7b4a                	ld	s6,176(sp)
ffffffffc0200d2e:	7bea                	ld	s7,184(sp)
ffffffffc0200d30:	6c0e                	ld	s8,192(sp)
ffffffffc0200d32:	6cae                	ld	s9,200(sp)
ffffffffc0200d34:	6d4e                	ld	s10,208(sp)
ffffffffc0200d36:	6dee                	ld	s11,216(sp)
ffffffffc0200d38:	7e0e                	ld	t3,224(sp)
ffffffffc0200d3a:	7eae                	ld	t4,232(sp)
ffffffffc0200d3c:	7f4e                	ld	t5,240(sp)
ffffffffc0200d3e:	7fee                	ld	t6,248(sp)
ffffffffc0200d40:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200d42:	10200073          	sret

ffffffffc0200d46 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200d46:	00006797          	auipc	a5,0x6
ffffffffc0200d4a:	2e278793          	addi	a5,a5,738 # ffffffffc0207028 <free_area>
ffffffffc0200d4e:	e79c                	sd	a5,8(a5)
ffffffffc0200d50:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200d52:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200d56:	8082                	ret

ffffffffc0200d58 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200d58:	00006517          	auipc	a0,0x6
ffffffffc0200d5c:	2e056503          	lwu	a0,736(a0) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200d60:	8082                	ret

ffffffffc0200d62 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200d62:	c14d                	beqz	a0,ffffffffc0200e04 <best_fit_alloc_pages+0xa2>
    if (n > nr_free) {
ffffffffc0200d64:	00006617          	auipc	a2,0x6
ffffffffc0200d68:	2c460613          	addi	a2,a2,708 # ffffffffc0207028 <free_area>
ffffffffc0200d6c:	01062803          	lw	a6,16(a2)
ffffffffc0200d70:	86aa                	mv	a3,a0
ffffffffc0200d72:	02081793          	slli	a5,a6,0x20
ffffffffc0200d76:	9381                	srli	a5,a5,0x20
ffffffffc0200d78:	08a7e463          	bltu	a5,a0,ffffffffc0200e00 <best_fit_alloc_pages+0x9e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200d7c:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200d7e:	0018059b          	addiw	a1,a6,1
ffffffffc0200d82:	1582                	slli	a1,a1,0x20
ffffffffc0200d84:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc0200d86:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d88:	06c78b63          	beq	a5,a2,ffffffffc0200dfe <best_fit_alloc_pages+0x9c>
        if (p->property >= n) {
ffffffffc0200d8c:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200d90:	00d76763          	bltu	a4,a3,ffffffffc0200d9e <best_fit_alloc_pages+0x3c>
            if (p->property < min_size) {
ffffffffc0200d94:	00b77563          	bgeu	a4,a1,ffffffffc0200d9e <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc0200d98:	fe878513          	addi	a0,a5,-24
ffffffffc0200d9c:	85ba                	mv	a1,a4
ffffffffc0200d9e:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200da0:	fec796e3          	bne	a5,a2,ffffffffc0200d8c <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc0200da4:	cd29                	beqz	a0,ffffffffc0200dfe <best_fit_alloc_pages+0x9c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200da6:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200da8:	6d18                	ld	a4,24(a0)
        if (page->property > n) {
ffffffffc0200daa:	490c                	lw	a1,16(a0)
            p->property = page->property - n;
ffffffffc0200dac:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200db0:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200db2:	e398                	sd	a4,0(a5)
        if (page->property > n) {
ffffffffc0200db4:	02059793          	slli	a5,a1,0x20
ffffffffc0200db8:	9381                	srli	a5,a5,0x20
ffffffffc0200dba:	02f6f863          	bgeu	a3,a5,ffffffffc0200dea <best_fit_alloc_pages+0x88>
            struct Page *p = page + n;
ffffffffc0200dbe:	00269793          	slli	a5,a3,0x2
ffffffffc0200dc2:	97b6                	add	a5,a5,a3
ffffffffc0200dc4:	078e                	slli	a5,a5,0x3
ffffffffc0200dc6:	97aa                	add	a5,a5,a0
            p->property = page->property - n;
ffffffffc0200dc8:	411585bb          	subw	a1,a1,a7
ffffffffc0200dcc:	cb8c                	sw	a1,16(a5)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200dce:	4689                	li	a3,2
ffffffffc0200dd0:	00878593          	addi	a1,a5,8
ffffffffc0200dd4:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200dd8:	6714                	ld	a3,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc0200dda:	01878593          	addi	a1,a5,24
        nr_free -= n;
ffffffffc0200dde:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc0200de2:	e28c                	sd	a1,0(a3)
ffffffffc0200de4:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc0200de6:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc0200de8:	ef98                	sd	a4,24(a5)
ffffffffc0200dea:	4118083b          	subw	a6,a6,a7
ffffffffc0200dee:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200df2:	57f5                	li	a5,-3
ffffffffc0200df4:	00850713          	addi	a4,a0,8
ffffffffc0200df8:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc0200dfc:	8082                	ret
}
ffffffffc0200dfe:	8082                	ret
        return NULL;
ffffffffc0200e00:	4501                	li	a0,0
ffffffffc0200e02:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200e04:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200e06:	00002697          	auipc	a3,0x2
ffffffffc0200e0a:	bfa68693          	addi	a3,a3,-1030 # ffffffffc0202a00 <commands+0x7c0>
ffffffffc0200e0e:	00002617          	auipc	a2,0x2
ffffffffc0200e12:	bfa60613          	addi	a2,a2,-1030 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0200e16:	07200593          	li	a1,114
ffffffffc0200e1a:	00002517          	auipc	a0,0x2
ffffffffc0200e1e:	c0650513          	addi	a0,a0,-1018 # ffffffffc0202a20 <commands+0x7e0>
best_fit_alloc_pages(size_t n) {
ffffffffc0200e22:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200e24:	dd2ff0ef          	jal	ra,ffffffffc02003f6 <__panic>

ffffffffc0200e28 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200e28:	715d                	addi	sp,sp,-80
ffffffffc0200e2a:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0200e2c:	00006417          	auipc	s0,0x6
ffffffffc0200e30:	1fc40413          	addi	s0,s0,508 # ffffffffc0207028 <free_area>
ffffffffc0200e34:	641c                	ld	a5,8(s0)
ffffffffc0200e36:	e486                	sd	ra,72(sp)
ffffffffc0200e38:	fc26                	sd	s1,56(sp)
ffffffffc0200e3a:	f84a                	sd	s2,48(sp)
ffffffffc0200e3c:	f44e                	sd	s3,40(sp)
ffffffffc0200e3e:	f052                	sd	s4,32(sp)
ffffffffc0200e40:	ec56                	sd	s5,24(sp)
ffffffffc0200e42:	e85a                	sd	s6,16(sp)
ffffffffc0200e44:	e45e                	sd	s7,8(sp)
ffffffffc0200e46:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e48:	26878b63          	beq	a5,s0,ffffffffc02010be <best_fit_check+0x296>
    int count = 0, total = 0;
ffffffffc0200e4c:	4481                	li	s1,0
ffffffffc0200e4e:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e50:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200e54:	8b09                	andi	a4,a4,2
ffffffffc0200e56:	26070863          	beqz	a4,ffffffffc02010c6 <best_fit_check+0x29e>
        count ++, total += p->property;
ffffffffc0200e5a:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e5e:	679c                	ld	a5,8(a5)
ffffffffc0200e60:	2905                	addiw	s2,s2,1
ffffffffc0200e62:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e64:	fe8796e3          	bne	a5,s0,ffffffffc0200e50 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200e68:	89a6                	mv	s3,s1
ffffffffc0200e6a:	14f000ef          	jal	ra,ffffffffc02017b8 <nr_free_pages>
ffffffffc0200e6e:	33351c63          	bne	a0,s3,ffffffffc02011a6 <best_fit_check+0x37e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e72:	4505                	li	a0,1
ffffffffc0200e74:	0c7000ef          	jal	ra,ffffffffc020173a <alloc_pages>
ffffffffc0200e78:	8a2a                	mv	s4,a0
ffffffffc0200e7a:	36050663          	beqz	a0,ffffffffc02011e6 <best_fit_check+0x3be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e7e:	4505                	li	a0,1
ffffffffc0200e80:	0bb000ef          	jal	ra,ffffffffc020173a <alloc_pages>
ffffffffc0200e84:	89aa                	mv	s3,a0
ffffffffc0200e86:	34050063          	beqz	a0,ffffffffc02011c6 <best_fit_check+0x39e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e8a:	4505                	li	a0,1
ffffffffc0200e8c:	0af000ef          	jal	ra,ffffffffc020173a <alloc_pages>
ffffffffc0200e90:	8aaa                	mv	s5,a0
ffffffffc0200e92:	2c050a63          	beqz	a0,ffffffffc0201166 <best_fit_check+0x33e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e96:	253a0863          	beq	s4,s3,ffffffffc02010e6 <best_fit_check+0x2be>
ffffffffc0200e9a:	24aa0663          	beq	s4,a0,ffffffffc02010e6 <best_fit_check+0x2be>
ffffffffc0200e9e:	24a98463          	beq	s3,a0,ffffffffc02010e6 <best_fit_check+0x2be>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200ea2:	000a2783          	lw	a5,0(s4)
ffffffffc0200ea6:	26079063          	bnez	a5,ffffffffc0201106 <best_fit_check+0x2de>
ffffffffc0200eaa:	0009a783          	lw	a5,0(s3)
ffffffffc0200eae:	24079c63          	bnez	a5,ffffffffc0201106 <best_fit_check+0x2de>
ffffffffc0200eb2:	411c                	lw	a5,0(a0)
ffffffffc0200eb4:	24079963          	bnez	a5,ffffffffc0201106 <best_fit_check+0x2de>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200eb8:	00006797          	auipc	a5,0x6
ffffffffc0200ebc:	5b87b783          	ld	a5,1464(a5) # ffffffffc0207470 <pages>
ffffffffc0200ec0:	40fa0733          	sub	a4,s4,a5
ffffffffc0200ec4:	870d                	srai	a4,a4,0x3
ffffffffc0200ec6:	00002597          	auipc	a1,0x2
ffffffffc0200eca:	24a5b583          	ld	a1,586(a1) # ffffffffc0203110 <error_string+0x38>
ffffffffc0200ece:	02b70733          	mul	a4,a4,a1
ffffffffc0200ed2:	00002617          	auipc	a2,0x2
ffffffffc0200ed6:	24663603          	ld	a2,582(a2) # ffffffffc0203118 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200eda:	00006697          	auipc	a3,0x6
ffffffffc0200ede:	58e6b683          	ld	a3,1422(a3) # ffffffffc0207468 <npage>
ffffffffc0200ee2:	06b2                	slli	a3,a3,0xc
ffffffffc0200ee4:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ee6:	0732                	slli	a4,a4,0xc
ffffffffc0200ee8:	22d77f63          	bgeu	a4,a3,ffffffffc0201126 <best_fit_check+0x2fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200eec:	40f98733          	sub	a4,s3,a5
ffffffffc0200ef0:	870d                	srai	a4,a4,0x3
ffffffffc0200ef2:	02b70733          	mul	a4,a4,a1
ffffffffc0200ef6:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ef8:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200efa:	3ed77663          	bgeu	a4,a3,ffffffffc02012e6 <best_fit_check+0x4be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200efe:	40f507b3          	sub	a5,a0,a5
ffffffffc0200f02:	878d                	srai	a5,a5,0x3
ffffffffc0200f04:	02b787b3          	mul	a5,a5,a1
ffffffffc0200f08:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f0a:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f0c:	3ad7fd63          	bgeu	a5,a3,ffffffffc02012c6 <best_fit_check+0x49e>
    assert(alloc_page() == NULL);
ffffffffc0200f10:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f12:	00043c03          	ld	s8,0(s0)
ffffffffc0200f16:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200f1a:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200f1e:	e400                	sd	s0,8(s0)
ffffffffc0200f20:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200f22:	00006797          	auipc	a5,0x6
ffffffffc0200f26:	1007ab23          	sw	zero,278(a5) # ffffffffc0207038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200f2a:	011000ef          	jal	ra,ffffffffc020173a <alloc_pages>
ffffffffc0200f2e:	36051c63          	bnez	a0,ffffffffc02012a6 <best_fit_check+0x47e>
    free_page(p0);
ffffffffc0200f32:	4585                	li	a1,1
ffffffffc0200f34:	8552                	mv	a0,s4
ffffffffc0200f36:	043000ef          	jal	ra,ffffffffc0201778 <free_pages>
    free_page(p1);
ffffffffc0200f3a:	4585                	li	a1,1
ffffffffc0200f3c:	854e                	mv	a0,s3
ffffffffc0200f3e:	03b000ef          	jal	ra,ffffffffc0201778 <free_pages>
    free_page(p2);
ffffffffc0200f42:	4585                	li	a1,1
ffffffffc0200f44:	8556                	mv	a0,s5
ffffffffc0200f46:	033000ef          	jal	ra,ffffffffc0201778 <free_pages>
    assert(nr_free == 3);
ffffffffc0200f4a:	4818                	lw	a4,16(s0)
ffffffffc0200f4c:	478d                	li	a5,3
ffffffffc0200f4e:	32f71c63          	bne	a4,a5,ffffffffc0201286 <best_fit_check+0x45e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f52:	4505                	li	a0,1
ffffffffc0200f54:	7e6000ef          	jal	ra,ffffffffc020173a <alloc_pages>
ffffffffc0200f58:	89aa                	mv	s3,a0
ffffffffc0200f5a:	30050663          	beqz	a0,ffffffffc0201266 <best_fit_check+0x43e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f5e:	4505                	li	a0,1
ffffffffc0200f60:	7da000ef          	jal	ra,ffffffffc020173a <alloc_pages>
ffffffffc0200f64:	8aaa                	mv	s5,a0
ffffffffc0200f66:	2e050063          	beqz	a0,ffffffffc0201246 <best_fit_check+0x41e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f6a:	4505                	li	a0,1
ffffffffc0200f6c:	7ce000ef          	jal	ra,ffffffffc020173a <alloc_pages>
ffffffffc0200f70:	8a2a                	mv	s4,a0
ffffffffc0200f72:	2a050a63          	beqz	a0,ffffffffc0201226 <best_fit_check+0x3fe>
    assert(alloc_page() == NULL);
ffffffffc0200f76:	4505                	li	a0,1
ffffffffc0200f78:	7c2000ef          	jal	ra,ffffffffc020173a <alloc_pages>
ffffffffc0200f7c:	28051563          	bnez	a0,ffffffffc0201206 <best_fit_check+0x3de>
    free_page(p0);
ffffffffc0200f80:	4585                	li	a1,1
ffffffffc0200f82:	854e                	mv	a0,s3
ffffffffc0200f84:	7f4000ef          	jal	ra,ffffffffc0201778 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200f88:	641c                	ld	a5,8(s0)
ffffffffc0200f8a:	1a878e63          	beq	a5,s0,ffffffffc0201146 <best_fit_check+0x31e>
    assert((p = alloc_page()) == p0);
ffffffffc0200f8e:	4505                	li	a0,1
ffffffffc0200f90:	7aa000ef          	jal	ra,ffffffffc020173a <alloc_pages>
ffffffffc0200f94:	52a99963          	bne	s3,a0,ffffffffc02014c6 <best_fit_check+0x69e>
    assert(alloc_page() == NULL);
ffffffffc0200f98:	4505                	li	a0,1
ffffffffc0200f9a:	7a0000ef          	jal	ra,ffffffffc020173a <alloc_pages>
ffffffffc0200f9e:	50051463          	bnez	a0,ffffffffc02014a6 <best_fit_check+0x67e>
    assert(nr_free == 0);
ffffffffc0200fa2:	481c                	lw	a5,16(s0)
ffffffffc0200fa4:	4e079163          	bnez	a5,ffffffffc0201486 <best_fit_check+0x65e>
    free_page(p);
ffffffffc0200fa8:	854e                	mv	a0,s3
ffffffffc0200faa:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200fac:	01843023          	sd	s8,0(s0)
ffffffffc0200fb0:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200fb4:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200fb8:	7c0000ef          	jal	ra,ffffffffc0201778 <free_pages>
    free_page(p1);
ffffffffc0200fbc:	4585                	li	a1,1
ffffffffc0200fbe:	8556                	mv	a0,s5
ffffffffc0200fc0:	7b8000ef          	jal	ra,ffffffffc0201778 <free_pages>
    free_page(p2);
ffffffffc0200fc4:	4585                	li	a1,1
ffffffffc0200fc6:	8552                	mv	a0,s4
ffffffffc0200fc8:	7b0000ef          	jal	ra,ffffffffc0201778 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200fcc:	4515                	li	a0,5
ffffffffc0200fce:	76c000ef          	jal	ra,ffffffffc020173a <alloc_pages>
ffffffffc0200fd2:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200fd4:	48050963          	beqz	a0,ffffffffc0201466 <best_fit_check+0x63e>
ffffffffc0200fd8:	651c                	ld	a5,8(a0)
ffffffffc0200fda:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200fdc:	8b85                	andi	a5,a5,1
ffffffffc0200fde:	46079463          	bnez	a5,ffffffffc0201446 <best_fit_check+0x61e>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200fe2:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200fe4:	00043a83          	ld	s5,0(s0)
ffffffffc0200fe8:	00843a03          	ld	s4,8(s0)
ffffffffc0200fec:	e000                	sd	s0,0(s0)
ffffffffc0200fee:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200ff0:	74a000ef          	jal	ra,ffffffffc020173a <alloc_pages>
ffffffffc0200ff4:	42051963          	bnez	a0,ffffffffc0201426 <best_fit_check+0x5fe>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200ff8:	4589                	li	a1,2
ffffffffc0200ffa:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200ffe:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0201002:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0201006:	00006797          	auipc	a5,0x6
ffffffffc020100a:	0207a923          	sw	zero,50(a5) # ffffffffc0207038 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc020100e:	76a000ef          	jal	ra,ffffffffc0201778 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0201012:	8562                	mv	a0,s8
ffffffffc0201014:	4585                	li	a1,1
ffffffffc0201016:	762000ef          	jal	ra,ffffffffc0201778 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020101a:	4511                	li	a0,4
ffffffffc020101c:	71e000ef          	jal	ra,ffffffffc020173a <alloc_pages>
ffffffffc0201020:	3e051363          	bnez	a0,ffffffffc0201406 <best_fit_check+0x5de>
ffffffffc0201024:	0309b783          	ld	a5,48(s3)
ffffffffc0201028:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc020102a:	8b85                	andi	a5,a5,1
ffffffffc020102c:	3a078d63          	beqz	a5,ffffffffc02013e6 <best_fit_check+0x5be>
ffffffffc0201030:	0389a703          	lw	a4,56(s3)
ffffffffc0201034:	4789                	li	a5,2
ffffffffc0201036:	3af71863          	bne	a4,a5,ffffffffc02013e6 <best_fit_check+0x5be>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc020103a:	4505                	li	a0,1
ffffffffc020103c:	6fe000ef          	jal	ra,ffffffffc020173a <alloc_pages>
ffffffffc0201040:	8baa                	mv	s7,a0
ffffffffc0201042:	38050263          	beqz	a0,ffffffffc02013c6 <best_fit_check+0x59e>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0201046:	4509                	li	a0,2
ffffffffc0201048:	6f2000ef          	jal	ra,ffffffffc020173a <alloc_pages>
ffffffffc020104c:	34050d63          	beqz	a0,ffffffffc02013a6 <best_fit_check+0x57e>
    assert(p0 + 4 == p1);
ffffffffc0201050:	337c1b63          	bne	s8,s7,ffffffffc0201386 <best_fit_check+0x55e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0201054:	854e                	mv	a0,s3
ffffffffc0201056:	4595                	li	a1,5
ffffffffc0201058:	720000ef          	jal	ra,ffffffffc0201778 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020105c:	4515                	li	a0,5
ffffffffc020105e:	6dc000ef          	jal	ra,ffffffffc020173a <alloc_pages>
ffffffffc0201062:	89aa                	mv	s3,a0
ffffffffc0201064:	30050163          	beqz	a0,ffffffffc0201366 <best_fit_check+0x53e>
    assert(alloc_page() == NULL);
ffffffffc0201068:	4505                	li	a0,1
ffffffffc020106a:	6d0000ef          	jal	ra,ffffffffc020173a <alloc_pages>
ffffffffc020106e:	2c051c63          	bnez	a0,ffffffffc0201346 <best_fit_check+0x51e>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0201072:	481c                	lw	a5,16(s0)
ffffffffc0201074:	2a079963          	bnez	a5,ffffffffc0201326 <best_fit_check+0x4fe>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201078:	4595                	li	a1,5
ffffffffc020107a:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020107c:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0201080:	01543023          	sd	s5,0(s0)
ffffffffc0201084:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0201088:	6f0000ef          	jal	ra,ffffffffc0201778 <free_pages>
    return listelm->next;
ffffffffc020108c:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020108e:	00878963          	beq	a5,s0,ffffffffc02010a0 <best_fit_check+0x278>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0201092:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201096:	679c                	ld	a5,8(a5)
ffffffffc0201098:	397d                	addiw	s2,s2,-1
ffffffffc020109a:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020109c:	fe879be3          	bne	a5,s0,ffffffffc0201092 <best_fit_check+0x26a>
    }
    assert(count == 0);
ffffffffc02010a0:	26091363          	bnez	s2,ffffffffc0201306 <best_fit_check+0x4de>
    assert(total == 0);
ffffffffc02010a4:	e0ed                	bnez	s1,ffffffffc0201186 <best_fit_check+0x35e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc02010a6:	60a6                	ld	ra,72(sp)
ffffffffc02010a8:	6406                	ld	s0,64(sp)
ffffffffc02010aa:	74e2                	ld	s1,56(sp)
ffffffffc02010ac:	7942                	ld	s2,48(sp)
ffffffffc02010ae:	79a2                	ld	s3,40(sp)
ffffffffc02010b0:	7a02                	ld	s4,32(sp)
ffffffffc02010b2:	6ae2                	ld	s5,24(sp)
ffffffffc02010b4:	6b42                	ld	s6,16(sp)
ffffffffc02010b6:	6ba2                	ld	s7,8(sp)
ffffffffc02010b8:	6c02                	ld	s8,0(sp)
ffffffffc02010ba:	6161                	addi	sp,sp,80
ffffffffc02010bc:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010be:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02010c0:	4481                	li	s1,0
ffffffffc02010c2:	4901                	li	s2,0
ffffffffc02010c4:	b35d                	j	ffffffffc0200e6a <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc02010c6:	00002697          	auipc	a3,0x2
ffffffffc02010ca:	97268693          	addi	a3,a3,-1678 # ffffffffc0202a38 <commands+0x7f8>
ffffffffc02010ce:	00002617          	auipc	a2,0x2
ffffffffc02010d2:	93a60613          	addi	a2,a2,-1734 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc02010d6:	11900593          	li	a1,281
ffffffffc02010da:	00002517          	auipc	a0,0x2
ffffffffc02010de:	94650513          	addi	a0,a0,-1722 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc02010e2:	b14ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02010e6:	00002697          	auipc	a3,0x2
ffffffffc02010ea:	9e268693          	addi	a3,a3,-1566 # ffffffffc0202ac8 <commands+0x888>
ffffffffc02010ee:	00002617          	auipc	a2,0x2
ffffffffc02010f2:	91a60613          	addi	a2,a2,-1766 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc02010f6:	0e500593          	li	a1,229
ffffffffc02010fa:	00002517          	auipc	a0,0x2
ffffffffc02010fe:	92650513          	addi	a0,a0,-1754 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201102:	af4ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201106:	00002697          	auipc	a3,0x2
ffffffffc020110a:	9ea68693          	addi	a3,a3,-1558 # ffffffffc0202af0 <commands+0x8b0>
ffffffffc020110e:	00002617          	auipc	a2,0x2
ffffffffc0201112:	8fa60613          	addi	a2,a2,-1798 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201116:	0e600593          	li	a1,230
ffffffffc020111a:	00002517          	auipc	a0,0x2
ffffffffc020111e:	90650513          	addi	a0,a0,-1786 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201122:	ad4ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201126:	00002697          	auipc	a3,0x2
ffffffffc020112a:	a0a68693          	addi	a3,a3,-1526 # ffffffffc0202b30 <commands+0x8f0>
ffffffffc020112e:	00002617          	auipc	a2,0x2
ffffffffc0201132:	8da60613          	addi	a2,a2,-1830 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201136:	0e800593          	li	a1,232
ffffffffc020113a:	00002517          	auipc	a0,0x2
ffffffffc020113e:	8e650513          	addi	a0,a0,-1818 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201142:	ab4ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201146:	00002697          	auipc	a3,0x2
ffffffffc020114a:	a7268693          	addi	a3,a3,-1422 # ffffffffc0202bb8 <commands+0x978>
ffffffffc020114e:	00002617          	auipc	a2,0x2
ffffffffc0201152:	8ba60613          	addi	a2,a2,-1862 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201156:	10100593          	li	a1,257
ffffffffc020115a:	00002517          	auipc	a0,0x2
ffffffffc020115e:	8c650513          	addi	a0,a0,-1850 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201162:	a94ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201166:	00002697          	auipc	a3,0x2
ffffffffc020116a:	94268693          	addi	a3,a3,-1726 # ffffffffc0202aa8 <commands+0x868>
ffffffffc020116e:	00002617          	auipc	a2,0x2
ffffffffc0201172:	89a60613          	addi	a2,a2,-1894 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201176:	0e300593          	li	a1,227
ffffffffc020117a:	00002517          	auipc	a0,0x2
ffffffffc020117e:	8a650513          	addi	a0,a0,-1882 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201182:	a74ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(total == 0);
ffffffffc0201186:	00002697          	auipc	a3,0x2
ffffffffc020118a:	b6268693          	addi	a3,a3,-1182 # ffffffffc0202ce8 <commands+0xaa8>
ffffffffc020118e:	00002617          	auipc	a2,0x2
ffffffffc0201192:	87a60613          	addi	a2,a2,-1926 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201196:	15b00593          	li	a1,347
ffffffffc020119a:	00002517          	auipc	a0,0x2
ffffffffc020119e:	88650513          	addi	a0,a0,-1914 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc02011a2:	a54ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(total == nr_free_pages());
ffffffffc02011a6:	00002697          	auipc	a3,0x2
ffffffffc02011aa:	8a268693          	addi	a3,a3,-1886 # ffffffffc0202a48 <commands+0x808>
ffffffffc02011ae:	00002617          	auipc	a2,0x2
ffffffffc02011b2:	85a60613          	addi	a2,a2,-1958 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc02011b6:	11c00593          	li	a1,284
ffffffffc02011ba:	00002517          	auipc	a0,0x2
ffffffffc02011be:	86650513          	addi	a0,a0,-1946 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc02011c2:	a34ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02011c6:	00002697          	auipc	a3,0x2
ffffffffc02011ca:	8c268693          	addi	a3,a3,-1854 # ffffffffc0202a88 <commands+0x848>
ffffffffc02011ce:	00002617          	auipc	a2,0x2
ffffffffc02011d2:	83a60613          	addi	a2,a2,-1990 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc02011d6:	0e200593          	li	a1,226
ffffffffc02011da:	00002517          	auipc	a0,0x2
ffffffffc02011de:	84650513          	addi	a0,a0,-1978 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc02011e2:	a14ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02011e6:	00002697          	auipc	a3,0x2
ffffffffc02011ea:	88268693          	addi	a3,a3,-1918 # ffffffffc0202a68 <commands+0x828>
ffffffffc02011ee:	00002617          	auipc	a2,0x2
ffffffffc02011f2:	81a60613          	addi	a2,a2,-2022 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc02011f6:	0e100593          	li	a1,225
ffffffffc02011fa:	00002517          	auipc	a0,0x2
ffffffffc02011fe:	82650513          	addi	a0,a0,-2010 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201202:	9f4ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201206:	00002697          	auipc	a3,0x2
ffffffffc020120a:	98a68693          	addi	a3,a3,-1654 # ffffffffc0202b90 <commands+0x950>
ffffffffc020120e:	00001617          	auipc	a2,0x1
ffffffffc0201212:	7fa60613          	addi	a2,a2,2042 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201216:	0fe00593          	li	a1,254
ffffffffc020121a:	00002517          	auipc	a0,0x2
ffffffffc020121e:	80650513          	addi	a0,a0,-2042 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201222:	9d4ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201226:	00002697          	auipc	a3,0x2
ffffffffc020122a:	88268693          	addi	a3,a3,-1918 # ffffffffc0202aa8 <commands+0x868>
ffffffffc020122e:	00001617          	auipc	a2,0x1
ffffffffc0201232:	7da60613          	addi	a2,a2,2010 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201236:	0fc00593          	li	a1,252
ffffffffc020123a:	00001517          	auipc	a0,0x1
ffffffffc020123e:	7e650513          	addi	a0,a0,2022 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201242:	9b4ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201246:	00002697          	auipc	a3,0x2
ffffffffc020124a:	84268693          	addi	a3,a3,-1982 # ffffffffc0202a88 <commands+0x848>
ffffffffc020124e:	00001617          	auipc	a2,0x1
ffffffffc0201252:	7ba60613          	addi	a2,a2,1978 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201256:	0fb00593          	li	a1,251
ffffffffc020125a:	00001517          	auipc	a0,0x1
ffffffffc020125e:	7c650513          	addi	a0,a0,1990 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201262:	994ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201266:	00002697          	auipc	a3,0x2
ffffffffc020126a:	80268693          	addi	a3,a3,-2046 # ffffffffc0202a68 <commands+0x828>
ffffffffc020126e:	00001617          	auipc	a2,0x1
ffffffffc0201272:	79a60613          	addi	a2,a2,1946 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201276:	0fa00593          	li	a1,250
ffffffffc020127a:	00001517          	auipc	a0,0x1
ffffffffc020127e:	7a650513          	addi	a0,a0,1958 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201282:	974ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(nr_free == 3);
ffffffffc0201286:	00002697          	auipc	a3,0x2
ffffffffc020128a:	92268693          	addi	a3,a3,-1758 # ffffffffc0202ba8 <commands+0x968>
ffffffffc020128e:	00001617          	auipc	a2,0x1
ffffffffc0201292:	77a60613          	addi	a2,a2,1914 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201296:	0f800593          	li	a1,248
ffffffffc020129a:	00001517          	auipc	a0,0x1
ffffffffc020129e:	78650513          	addi	a0,a0,1926 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc02012a2:	954ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012a6:	00002697          	auipc	a3,0x2
ffffffffc02012aa:	8ea68693          	addi	a3,a3,-1814 # ffffffffc0202b90 <commands+0x950>
ffffffffc02012ae:	00001617          	auipc	a2,0x1
ffffffffc02012b2:	75a60613          	addi	a2,a2,1882 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc02012b6:	0f300593          	li	a1,243
ffffffffc02012ba:	00001517          	auipc	a0,0x1
ffffffffc02012be:	76650513          	addi	a0,a0,1894 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc02012c2:	934ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02012c6:	00002697          	auipc	a3,0x2
ffffffffc02012ca:	8aa68693          	addi	a3,a3,-1878 # ffffffffc0202b70 <commands+0x930>
ffffffffc02012ce:	00001617          	auipc	a2,0x1
ffffffffc02012d2:	73a60613          	addi	a2,a2,1850 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc02012d6:	0ea00593          	li	a1,234
ffffffffc02012da:	00001517          	auipc	a0,0x1
ffffffffc02012de:	74650513          	addi	a0,a0,1862 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc02012e2:	914ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02012e6:	00002697          	auipc	a3,0x2
ffffffffc02012ea:	86a68693          	addi	a3,a3,-1942 # ffffffffc0202b50 <commands+0x910>
ffffffffc02012ee:	00001617          	auipc	a2,0x1
ffffffffc02012f2:	71a60613          	addi	a2,a2,1818 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc02012f6:	0e900593          	li	a1,233
ffffffffc02012fa:	00001517          	auipc	a0,0x1
ffffffffc02012fe:	72650513          	addi	a0,a0,1830 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201302:	8f4ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(count == 0);
ffffffffc0201306:	00002697          	auipc	a3,0x2
ffffffffc020130a:	9d268693          	addi	a3,a3,-1582 # ffffffffc0202cd8 <commands+0xa98>
ffffffffc020130e:	00001617          	auipc	a2,0x1
ffffffffc0201312:	6fa60613          	addi	a2,a2,1786 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201316:	15a00593          	li	a1,346
ffffffffc020131a:	00001517          	auipc	a0,0x1
ffffffffc020131e:	70650513          	addi	a0,a0,1798 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201322:	8d4ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(nr_free == 0);
ffffffffc0201326:	00002697          	auipc	a3,0x2
ffffffffc020132a:	8ca68693          	addi	a3,a3,-1846 # ffffffffc0202bf0 <commands+0x9b0>
ffffffffc020132e:	00001617          	auipc	a2,0x1
ffffffffc0201332:	6da60613          	addi	a2,a2,1754 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201336:	14f00593          	li	a1,335
ffffffffc020133a:	00001517          	auipc	a0,0x1
ffffffffc020133e:	6e650513          	addi	a0,a0,1766 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201342:	8b4ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201346:	00002697          	auipc	a3,0x2
ffffffffc020134a:	84a68693          	addi	a3,a3,-1974 # ffffffffc0202b90 <commands+0x950>
ffffffffc020134e:	00001617          	auipc	a2,0x1
ffffffffc0201352:	6ba60613          	addi	a2,a2,1722 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201356:	14900593          	li	a1,329
ffffffffc020135a:	00001517          	auipc	a0,0x1
ffffffffc020135e:	6c650513          	addi	a0,a0,1734 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201362:	894ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201366:	00002697          	auipc	a3,0x2
ffffffffc020136a:	95268693          	addi	a3,a3,-1710 # ffffffffc0202cb8 <commands+0xa78>
ffffffffc020136e:	00001617          	auipc	a2,0x1
ffffffffc0201372:	69a60613          	addi	a2,a2,1690 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201376:	14800593          	li	a1,328
ffffffffc020137a:	00001517          	auipc	a0,0x1
ffffffffc020137e:	6a650513          	addi	a0,a0,1702 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201382:	874ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0201386:	00002697          	auipc	a3,0x2
ffffffffc020138a:	92268693          	addi	a3,a3,-1758 # ffffffffc0202ca8 <commands+0xa68>
ffffffffc020138e:	00001617          	auipc	a2,0x1
ffffffffc0201392:	67a60613          	addi	a2,a2,1658 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201396:	14000593          	li	a1,320
ffffffffc020139a:	00001517          	auipc	a0,0x1
ffffffffc020139e:	68650513          	addi	a0,a0,1670 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc02013a2:	854ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02013a6:	00002697          	auipc	a3,0x2
ffffffffc02013aa:	8ea68693          	addi	a3,a3,-1814 # ffffffffc0202c90 <commands+0xa50>
ffffffffc02013ae:	00001617          	auipc	a2,0x1
ffffffffc02013b2:	65a60613          	addi	a2,a2,1626 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc02013b6:	13f00593          	li	a1,319
ffffffffc02013ba:	00001517          	auipc	a0,0x1
ffffffffc02013be:	66650513          	addi	a0,a0,1638 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc02013c2:	834ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02013c6:	00002697          	auipc	a3,0x2
ffffffffc02013ca:	8aa68693          	addi	a3,a3,-1878 # ffffffffc0202c70 <commands+0xa30>
ffffffffc02013ce:	00001617          	auipc	a2,0x1
ffffffffc02013d2:	63a60613          	addi	a2,a2,1594 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc02013d6:	13e00593          	li	a1,318
ffffffffc02013da:	00001517          	auipc	a0,0x1
ffffffffc02013de:	64650513          	addi	a0,a0,1606 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc02013e2:	814ff0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc02013e6:	00002697          	auipc	a3,0x2
ffffffffc02013ea:	85a68693          	addi	a3,a3,-1958 # ffffffffc0202c40 <commands+0xa00>
ffffffffc02013ee:	00001617          	auipc	a2,0x1
ffffffffc02013f2:	61a60613          	addi	a2,a2,1562 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc02013f6:	13c00593          	li	a1,316
ffffffffc02013fa:	00001517          	auipc	a0,0x1
ffffffffc02013fe:	62650513          	addi	a0,a0,1574 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201402:	ff5fe0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201406:	00002697          	auipc	a3,0x2
ffffffffc020140a:	82268693          	addi	a3,a3,-2014 # ffffffffc0202c28 <commands+0x9e8>
ffffffffc020140e:	00001617          	auipc	a2,0x1
ffffffffc0201412:	5fa60613          	addi	a2,a2,1530 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201416:	13b00593          	li	a1,315
ffffffffc020141a:	00001517          	auipc	a0,0x1
ffffffffc020141e:	60650513          	addi	a0,a0,1542 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201422:	fd5fe0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201426:	00001697          	auipc	a3,0x1
ffffffffc020142a:	76a68693          	addi	a3,a3,1898 # ffffffffc0202b90 <commands+0x950>
ffffffffc020142e:	00001617          	auipc	a2,0x1
ffffffffc0201432:	5da60613          	addi	a2,a2,1498 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201436:	12f00593          	li	a1,303
ffffffffc020143a:	00001517          	auipc	a0,0x1
ffffffffc020143e:	5e650513          	addi	a0,a0,1510 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201442:	fb5fe0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201446:	00001697          	auipc	a3,0x1
ffffffffc020144a:	7ca68693          	addi	a3,a3,1994 # ffffffffc0202c10 <commands+0x9d0>
ffffffffc020144e:	00001617          	auipc	a2,0x1
ffffffffc0201452:	5ba60613          	addi	a2,a2,1466 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201456:	12600593          	li	a1,294
ffffffffc020145a:	00001517          	auipc	a0,0x1
ffffffffc020145e:	5c650513          	addi	a0,a0,1478 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201462:	f95fe0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(p0 != NULL);
ffffffffc0201466:	00001697          	auipc	a3,0x1
ffffffffc020146a:	79a68693          	addi	a3,a3,1946 # ffffffffc0202c00 <commands+0x9c0>
ffffffffc020146e:	00001617          	auipc	a2,0x1
ffffffffc0201472:	59a60613          	addi	a2,a2,1434 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201476:	12500593          	li	a1,293
ffffffffc020147a:	00001517          	auipc	a0,0x1
ffffffffc020147e:	5a650513          	addi	a0,a0,1446 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201482:	f75fe0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(nr_free == 0);
ffffffffc0201486:	00001697          	auipc	a3,0x1
ffffffffc020148a:	76a68693          	addi	a3,a3,1898 # ffffffffc0202bf0 <commands+0x9b0>
ffffffffc020148e:	00001617          	auipc	a2,0x1
ffffffffc0201492:	57a60613          	addi	a2,a2,1402 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc0201496:	10700593          	li	a1,263
ffffffffc020149a:	00001517          	auipc	a0,0x1
ffffffffc020149e:	58650513          	addi	a0,a0,1414 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc02014a2:	f55fe0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014a6:	00001697          	auipc	a3,0x1
ffffffffc02014aa:	6ea68693          	addi	a3,a3,1770 # ffffffffc0202b90 <commands+0x950>
ffffffffc02014ae:	00001617          	auipc	a2,0x1
ffffffffc02014b2:	55a60613          	addi	a2,a2,1370 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc02014b6:	10500593          	li	a1,261
ffffffffc02014ba:	00001517          	auipc	a0,0x1
ffffffffc02014be:	56650513          	addi	a0,a0,1382 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc02014c2:	f35fe0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02014c6:	00001697          	auipc	a3,0x1
ffffffffc02014ca:	70a68693          	addi	a3,a3,1802 # ffffffffc0202bd0 <commands+0x990>
ffffffffc02014ce:	00001617          	auipc	a2,0x1
ffffffffc02014d2:	53a60613          	addi	a2,a2,1338 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc02014d6:	10400593          	li	a1,260
ffffffffc02014da:	00001517          	auipc	a0,0x1
ffffffffc02014de:	54650513          	addi	a0,a0,1350 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc02014e2:	f15fe0ef          	jal	ra,ffffffffc02003f6 <__panic>

ffffffffc02014e6 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc02014e6:	1141                	addi	sp,sp,-16
ffffffffc02014e8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02014ea:	14058a63          	beqz	a1,ffffffffc020163e <best_fit_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc02014ee:	00259693          	slli	a3,a1,0x2
ffffffffc02014f2:	96ae                	add	a3,a3,a1
ffffffffc02014f4:	068e                	slli	a3,a3,0x3
ffffffffc02014f6:	96aa                	add	a3,a3,a0
ffffffffc02014f8:	87aa                	mv	a5,a0
ffffffffc02014fa:	02d50263          	beq	a0,a3,ffffffffc020151e <best_fit_free_pages+0x38>
ffffffffc02014fe:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201500:	8b05                	andi	a4,a4,1
ffffffffc0201502:	10071e63          	bnez	a4,ffffffffc020161e <best_fit_free_pages+0x138>
ffffffffc0201506:	6798                	ld	a4,8(a5)
ffffffffc0201508:	8b09                	andi	a4,a4,2
ffffffffc020150a:	10071a63          	bnez	a4,ffffffffc020161e <best_fit_free_pages+0x138>
        p->flags = 0;
ffffffffc020150e:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201512:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201516:	02878793          	addi	a5,a5,40
ffffffffc020151a:	fed792e3          	bne	a5,a3,ffffffffc02014fe <best_fit_free_pages+0x18>
    base->property = n;
ffffffffc020151e:	2581                	sext.w	a1,a1
ffffffffc0201520:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201522:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201526:	4789                	li	a5,2
ffffffffc0201528:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020152c:	00006697          	auipc	a3,0x6
ffffffffc0201530:	afc68693          	addi	a3,a3,-1284 # ffffffffc0207028 <free_area>
ffffffffc0201534:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201536:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201538:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020153c:	9db9                	addw	a1,a1,a4
ffffffffc020153e:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201540:	0ad78863          	beq	a5,a3,ffffffffc02015f0 <best_fit_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201544:	fe878713          	addi	a4,a5,-24
ffffffffc0201548:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020154c:	4581                	li	a1,0
            if (base < page) {
ffffffffc020154e:	00e56a63          	bltu	a0,a4,ffffffffc0201562 <best_fit_free_pages+0x7c>
    return listelm->next;
ffffffffc0201552:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201554:	06d70263          	beq	a4,a3,ffffffffc02015b8 <best_fit_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc0201558:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020155a:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020155e:	fee57ae3          	bgeu	a0,a4,ffffffffc0201552 <best_fit_free_pages+0x6c>
ffffffffc0201562:	c199                	beqz	a1,ffffffffc0201568 <best_fit_free_pages+0x82>
ffffffffc0201564:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201568:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc020156a:	e390                	sd	a2,0(a5)
ffffffffc020156c:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020156e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201570:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201572:	02d70063          	beq	a4,a3,ffffffffc0201592 <best_fit_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc0201576:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc020157a:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc020157e:	02081613          	slli	a2,a6,0x20
ffffffffc0201582:	9201                	srli	a2,a2,0x20
ffffffffc0201584:	00261793          	slli	a5,a2,0x2
ffffffffc0201588:	97b2                	add	a5,a5,a2
ffffffffc020158a:	078e                	slli	a5,a5,0x3
ffffffffc020158c:	97ae                	add	a5,a5,a1
ffffffffc020158e:	02f50f63          	beq	a0,a5,ffffffffc02015cc <best_fit_free_pages+0xe6>
    return listelm->next;
ffffffffc0201592:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc0201594:	00d70f63          	beq	a4,a3,ffffffffc02015b2 <best_fit_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc0201598:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc020159a:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc020159e:	02059613          	slli	a2,a1,0x20
ffffffffc02015a2:	9201                	srli	a2,a2,0x20
ffffffffc02015a4:	00261793          	slli	a5,a2,0x2
ffffffffc02015a8:	97b2                	add	a5,a5,a2
ffffffffc02015aa:	078e                	slli	a5,a5,0x3
ffffffffc02015ac:	97aa                	add	a5,a5,a0
ffffffffc02015ae:	04f68863          	beq	a3,a5,ffffffffc02015fe <best_fit_free_pages+0x118>
}
ffffffffc02015b2:	60a2                	ld	ra,8(sp)
ffffffffc02015b4:	0141                	addi	sp,sp,16
ffffffffc02015b6:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02015b8:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02015ba:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02015bc:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02015be:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015c0:	02d70563          	beq	a4,a3,ffffffffc02015ea <best_fit_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc02015c4:	8832                	mv	a6,a2
ffffffffc02015c6:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02015c8:	87ba                	mv	a5,a4
ffffffffc02015ca:	bf41                	j	ffffffffc020155a <best_fit_free_pages+0x74>
            p->property += base->property;
ffffffffc02015cc:	491c                	lw	a5,16(a0)
ffffffffc02015ce:	0107883b          	addw	a6,a5,a6
ffffffffc02015d2:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02015d6:	57f5                	li	a5,-3
ffffffffc02015d8:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02015dc:	6d10                	ld	a2,24(a0)
ffffffffc02015de:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc02015e0:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc02015e2:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc02015e4:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02015e6:	e390                	sd	a2,0(a5)
ffffffffc02015e8:	b775                	j	ffffffffc0201594 <best_fit_free_pages+0xae>
ffffffffc02015ea:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015ec:	873e                	mv	a4,a5
ffffffffc02015ee:	b761                	j	ffffffffc0201576 <best_fit_free_pages+0x90>
}
ffffffffc02015f0:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02015f2:	e390                	sd	a2,0(a5)
ffffffffc02015f4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02015f6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02015f8:	ed1c                	sd	a5,24(a0)
ffffffffc02015fa:	0141                	addi	sp,sp,16
ffffffffc02015fc:	8082                	ret
            base->property += p->property;
ffffffffc02015fe:	ff872783          	lw	a5,-8(a4)
ffffffffc0201602:	ff070693          	addi	a3,a4,-16
ffffffffc0201606:	9dbd                	addw	a1,a1,a5
ffffffffc0201608:	c90c                	sw	a1,16(a0)
ffffffffc020160a:	57f5                	li	a5,-3
ffffffffc020160c:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201610:	6314                	ld	a3,0(a4)
ffffffffc0201612:	671c                	ld	a5,8(a4)
}
ffffffffc0201614:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201616:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201618:	e394                	sd	a3,0(a5)
ffffffffc020161a:	0141                	addi	sp,sp,16
ffffffffc020161c:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020161e:	00001697          	auipc	a3,0x1
ffffffffc0201622:	6da68693          	addi	a3,a3,1754 # ffffffffc0202cf8 <commands+0xab8>
ffffffffc0201626:	00001617          	auipc	a2,0x1
ffffffffc020162a:	3e260613          	addi	a2,a2,994 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc020162e:	0a000593          	li	a1,160
ffffffffc0201632:	00001517          	auipc	a0,0x1
ffffffffc0201636:	3ee50513          	addi	a0,a0,1006 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc020163a:	dbdfe0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(n > 0);
ffffffffc020163e:	00001697          	auipc	a3,0x1
ffffffffc0201642:	3c268693          	addi	a3,a3,962 # ffffffffc0202a00 <commands+0x7c0>
ffffffffc0201646:	00001617          	auipc	a2,0x1
ffffffffc020164a:	3c260613          	addi	a2,a2,962 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc020164e:	09d00593          	li	a1,157
ffffffffc0201652:	00001517          	auipc	a0,0x1
ffffffffc0201656:	3ce50513          	addi	a0,a0,974 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc020165a:	d9dfe0ef          	jal	ra,ffffffffc02003f6 <__panic>

ffffffffc020165e <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc020165e:	1141                	addi	sp,sp,-16
ffffffffc0201660:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201662:	cdc5                	beqz	a1,ffffffffc020171a <best_fit_init_memmap+0xbc>
    for (; p != base + n; p ++) {
ffffffffc0201664:	00259693          	slli	a3,a1,0x2
ffffffffc0201668:	96ae                	add	a3,a3,a1
ffffffffc020166a:	068e                	slli	a3,a3,0x3
ffffffffc020166c:	96aa                	add	a3,a3,a0
ffffffffc020166e:	87aa                	mv	a5,a0
ffffffffc0201670:	00d50f63          	beq	a0,a3,ffffffffc020168e <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201674:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201676:	8b05                	andi	a4,a4,1
ffffffffc0201678:	c349                	beqz	a4,ffffffffc02016fa <best_fit_init_memmap+0x9c>
        p->flags = 0;
ffffffffc020167a:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc020167e:	0007a823          	sw	zero,16(a5)
ffffffffc0201682:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201686:	02878793          	addi	a5,a5,40
ffffffffc020168a:	fed795e3          	bne	a5,a3,ffffffffc0201674 <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc020168e:	2581                	sext.w	a1,a1
ffffffffc0201690:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201692:	4789                	li	a5,2
ffffffffc0201694:	00850713          	addi	a4,a0,8
ffffffffc0201698:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020169c:	00006697          	auipc	a3,0x6
ffffffffc02016a0:	98c68693          	addi	a3,a3,-1652 # ffffffffc0207028 <free_area>
ffffffffc02016a4:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02016a6:	669c                	ld	a5,8(a3)
ffffffffc02016a8:	9db9                	addw	a1,a1,a4
ffffffffc02016aa:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02016ac:	00d79763          	bne	a5,a3,ffffffffc02016ba <best_fit_init_memmap+0x5c>
ffffffffc02016b0:	a01d                	j	ffffffffc02016d6 <best_fit_init_memmap+0x78>
    return listelm->next;
ffffffffc02016b2:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02016b4:	02d70a63          	beq	a4,a3,ffffffffc02016e8 <best_fit_init_memmap+0x8a>
ffffffffc02016b8:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02016ba:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02016be:	fee57ae3          	bgeu	a0,a4,ffffffffc02016b2 <best_fit_init_memmap+0x54>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016c2:	6398                	ld	a4,0(a5)
                list_add_before(le, &(base->page_link));
ffffffffc02016c4:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc02016c8:	e394                	sd	a3,0(a5)
}
ffffffffc02016ca:	60a2                	ld	ra,8(sp)
ffffffffc02016cc:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc02016ce:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016d0:	ed18                	sd	a4,24(a0)
ffffffffc02016d2:	0141                	addi	sp,sp,16
ffffffffc02016d4:	8082                	ret
ffffffffc02016d6:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02016d8:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc02016dc:	e398                	sd	a4,0(a5)
ffffffffc02016de:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02016e0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016e2:	ed1c                	sd	a5,24(a0)
}
ffffffffc02016e4:	0141                	addi	sp,sp,16
ffffffffc02016e6:	8082                	ret
ffffffffc02016e8:	60a2                	ld	ra,8(sp)
                list_add(le, &(base->page_link));
ffffffffc02016ea:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc02016ee:	e798                	sd	a4,8(a5)
ffffffffc02016f0:	e298                	sd	a4,0(a3)
    elm->next = next;
ffffffffc02016f2:	f114                	sd	a3,32(a0)
    elm->prev = prev;
ffffffffc02016f4:	ed1c                	sd	a5,24(a0)
}
ffffffffc02016f6:	0141                	addi	sp,sp,16
ffffffffc02016f8:	8082                	ret
        assert(PageReserved(p));
ffffffffc02016fa:	00001697          	auipc	a3,0x1
ffffffffc02016fe:	62668693          	addi	a3,a3,1574 # ffffffffc0202d20 <commands+0xae0>
ffffffffc0201702:	00001617          	auipc	a2,0x1
ffffffffc0201706:	30660613          	addi	a2,a2,774 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc020170a:	04a00593          	li	a1,74
ffffffffc020170e:	00001517          	auipc	a0,0x1
ffffffffc0201712:	31250513          	addi	a0,a0,786 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201716:	ce1fe0ef          	jal	ra,ffffffffc02003f6 <__panic>
    assert(n > 0);
ffffffffc020171a:	00001697          	auipc	a3,0x1
ffffffffc020171e:	2e668693          	addi	a3,a3,742 # ffffffffc0202a00 <commands+0x7c0>
ffffffffc0201722:	00001617          	auipc	a2,0x1
ffffffffc0201726:	2e660613          	addi	a2,a2,742 # ffffffffc0202a08 <commands+0x7c8>
ffffffffc020172a:	04700593          	li	a1,71
ffffffffc020172e:	00001517          	auipc	a0,0x1
ffffffffc0201732:	2f250513          	addi	a0,a0,754 # ffffffffc0202a20 <commands+0x7e0>
ffffffffc0201736:	cc1fe0ef          	jal	ra,ffffffffc02003f6 <__panic>

ffffffffc020173a <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020173a:	100027f3          	csrr	a5,sstatus
ffffffffc020173e:	8b89                	andi	a5,a5,2
ffffffffc0201740:	e799                	bnez	a5,ffffffffc020174e <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201742:	00006797          	auipc	a5,0x6
ffffffffc0201746:	d367b783          	ld	a5,-714(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc020174a:	6f9c                	ld	a5,24(a5)
ffffffffc020174c:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc020174e:	1141                	addi	sp,sp,-16
ffffffffc0201750:	e406                	sd	ra,8(sp)
ffffffffc0201752:	e022                	sd	s0,0(sp)
ffffffffc0201754:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201756:	902ff0ef          	jal	ra,ffffffffc0200858 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020175a:	00006797          	auipc	a5,0x6
ffffffffc020175e:	d1e7b783          	ld	a5,-738(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0201762:	6f9c                	ld	a5,24(a5)
ffffffffc0201764:	8522                	mv	a0,s0
ffffffffc0201766:	9782                	jalr	a5
ffffffffc0201768:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc020176a:	8e8ff0ef          	jal	ra,ffffffffc0200852 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc020176e:	60a2                	ld	ra,8(sp)
ffffffffc0201770:	8522                	mv	a0,s0
ffffffffc0201772:	6402                	ld	s0,0(sp)
ffffffffc0201774:	0141                	addi	sp,sp,16
ffffffffc0201776:	8082                	ret

ffffffffc0201778 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201778:	100027f3          	csrr	a5,sstatus
ffffffffc020177c:	8b89                	andi	a5,a5,2
ffffffffc020177e:	e799                	bnez	a5,ffffffffc020178c <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201780:	00006797          	auipc	a5,0x6
ffffffffc0201784:	cf87b783          	ld	a5,-776(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0201788:	739c                	ld	a5,32(a5)
ffffffffc020178a:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc020178c:	1101                	addi	sp,sp,-32
ffffffffc020178e:	ec06                	sd	ra,24(sp)
ffffffffc0201790:	e822                	sd	s0,16(sp)
ffffffffc0201792:	e426                	sd	s1,8(sp)
ffffffffc0201794:	842a                	mv	s0,a0
ffffffffc0201796:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201798:	8c0ff0ef          	jal	ra,ffffffffc0200858 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020179c:	00006797          	auipc	a5,0x6
ffffffffc02017a0:	cdc7b783          	ld	a5,-804(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02017a4:	739c                	ld	a5,32(a5)
ffffffffc02017a6:	85a6                	mv	a1,s1
ffffffffc02017a8:	8522                	mv	a0,s0
ffffffffc02017aa:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02017ac:	6442                	ld	s0,16(sp)
ffffffffc02017ae:	60e2                	ld	ra,24(sp)
ffffffffc02017b0:	64a2                	ld	s1,8(sp)
ffffffffc02017b2:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02017b4:	89eff06f          	j	ffffffffc0200852 <intr_enable>

ffffffffc02017b8 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02017b8:	100027f3          	csrr	a5,sstatus
ffffffffc02017bc:	8b89                	andi	a5,a5,2
ffffffffc02017be:	e799                	bnez	a5,ffffffffc02017cc <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02017c0:	00006797          	auipc	a5,0x6
ffffffffc02017c4:	cb87b783          	ld	a5,-840(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02017c8:	779c                	ld	a5,40(a5)
ffffffffc02017ca:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc02017cc:	1141                	addi	sp,sp,-16
ffffffffc02017ce:	e406                	sd	ra,8(sp)
ffffffffc02017d0:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02017d2:	886ff0ef          	jal	ra,ffffffffc0200858 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02017d6:	00006797          	auipc	a5,0x6
ffffffffc02017da:	ca27b783          	ld	a5,-862(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02017de:	779c                	ld	a5,40(a5)
ffffffffc02017e0:	9782                	jalr	a5
ffffffffc02017e2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02017e4:	86eff0ef          	jal	ra,ffffffffc0200852 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02017e8:	60a2                	ld	ra,8(sp)
ffffffffc02017ea:	8522                	mv	a0,s0
ffffffffc02017ec:	6402                	ld	s0,0(sp)
ffffffffc02017ee:	0141                	addi	sp,sp,16
ffffffffc02017f0:	8082                	ret

ffffffffc02017f2 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02017f2:	00001797          	auipc	a5,0x1
ffffffffc02017f6:	55678793          	addi	a5,a5,1366 # ffffffffc0202d48 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017fa:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02017fc:	7179                	addi	sp,sp,-48
ffffffffc02017fe:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201800:	00001517          	auipc	a0,0x1
ffffffffc0201804:	58050513          	addi	a0,a0,1408 # ffffffffc0202d80 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201808:	00006417          	auipc	s0,0x6
ffffffffc020180c:	c7040413          	addi	s0,s0,-912 # ffffffffc0207478 <pmm_manager>
void pmm_init(void) {
ffffffffc0201810:	f406                	sd	ra,40(sp)
ffffffffc0201812:	ec26                	sd	s1,24(sp)
ffffffffc0201814:	e44e                	sd	s3,8(sp)
ffffffffc0201816:	e84a                	sd	s2,16(sp)
ffffffffc0201818:	e052                	sd	s4,0(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020181a:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020181c:	8e1fe0ef          	jal	ra,ffffffffc02000fc <cprintf>
    pmm_manager->init();
ffffffffc0201820:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201822:	00006497          	auipc	s1,0x6
ffffffffc0201826:	c6e48493          	addi	s1,s1,-914 # ffffffffc0207490 <va_pa_offset>
    pmm_manager->init();
ffffffffc020182a:	679c                	ld	a5,8(a5)
ffffffffc020182c:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020182e:	57f5                	li	a5,-3
ffffffffc0201830:	07fa                	slli	a5,a5,0x1e
ffffffffc0201832:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201834:	80aff0ef          	jal	ra,ffffffffc020083e <get_memory_base>
ffffffffc0201838:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020183a:	80eff0ef          	jal	ra,ffffffffc0200848 <get_memory_size>
    if (mem_size == 0) {
ffffffffc020183e:	16050163          	beqz	a0,ffffffffc02019a0 <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201842:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0201844:	00001517          	auipc	a0,0x1
ffffffffc0201848:	58450513          	addi	a0,a0,1412 # ffffffffc0202dc8 <best_fit_pmm_manager+0x80>
ffffffffc020184c:	8b1fe0ef          	jal	ra,ffffffffc02000fc <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201850:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201854:	864e                	mv	a2,s3
ffffffffc0201856:	fffa0693          	addi	a3,s4,-1
ffffffffc020185a:	85ca                	mv	a1,s2
ffffffffc020185c:	00001517          	auipc	a0,0x1
ffffffffc0201860:	58450513          	addi	a0,a0,1412 # ffffffffc0202de0 <best_fit_pmm_manager+0x98>
ffffffffc0201864:	899fe0ef          	jal	ra,ffffffffc02000fc <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201868:	c80007b7          	lui	a5,0xc8000
ffffffffc020186c:	8652                	mv	a2,s4
ffffffffc020186e:	0d47e863          	bltu	a5,s4,ffffffffc020193e <pmm_init+0x14c>
ffffffffc0201872:	00007797          	auipc	a5,0x7
ffffffffc0201876:	c2d78793          	addi	a5,a5,-979 # ffffffffc020849f <end+0xfff>
ffffffffc020187a:	757d                	lui	a0,0xfffff
ffffffffc020187c:	8d7d                	and	a0,a0,a5
ffffffffc020187e:	8231                	srli	a2,a2,0xc
ffffffffc0201880:	00006597          	auipc	a1,0x6
ffffffffc0201884:	be858593          	addi	a1,a1,-1048 # ffffffffc0207468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201888:	00006817          	auipc	a6,0x6
ffffffffc020188c:	be880813          	addi	a6,a6,-1048 # ffffffffc0207470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201890:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201892:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201896:	000807b7          	lui	a5,0x80
ffffffffc020189a:	02f60663          	beq	a2,a5,ffffffffc02018c6 <pmm_init+0xd4>
ffffffffc020189e:	4701                	li	a4,0
ffffffffc02018a0:	4781                	li	a5,0
ffffffffc02018a2:	4305                	li	t1,1
ffffffffc02018a4:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc02018a8:	953a                	add	a0,a0,a4
ffffffffc02018aa:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf7b68>
ffffffffc02018ae:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02018b2:	6190                	ld	a2,0(a1)
ffffffffc02018b4:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02018b6:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02018ba:	011606b3          	add	a3,a2,a7
ffffffffc02018be:	02870713          	addi	a4,a4,40
ffffffffc02018c2:	fed7e3e3          	bltu	a5,a3,ffffffffc02018a8 <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018c6:	00261693          	slli	a3,a2,0x2
ffffffffc02018ca:	96b2                	add	a3,a3,a2
ffffffffc02018cc:	fec007b7          	lui	a5,0xfec00
ffffffffc02018d0:	97aa                	add	a5,a5,a0
ffffffffc02018d2:	068e                	slli	a3,a3,0x3
ffffffffc02018d4:	96be                	add	a3,a3,a5
ffffffffc02018d6:	c02007b7          	lui	a5,0xc0200
ffffffffc02018da:	0af6e763          	bltu	a3,a5,ffffffffc0201988 <pmm_init+0x196>
ffffffffc02018de:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02018e0:	77fd                	lui	a5,0xfffff
ffffffffc02018e2:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018e6:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02018e8:	04b6ee63          	bltu	a3,a1,ffffffffc0201944 <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02018ec:	601c                	ld	a5,0(s0)
ffffffffc02018ee:	7b9c                	ld	a5,48(a5)
ffffffffc02018f0:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02018f2:	00001517          	auipc	a0,0x1
ffffffffc02018f6:	57650513          	addi	a0,a0,1398 # ffffffffc0202e68 <best_fit_pmm_manager+0x120>
ffffffffc02018fa:	803fe0ef          	jal	ra,ffffffffc02000fc <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02018fe:	00004597          	auipc	a1,0x4
ffffffffc0201902:	70258593          	addi	a1,a1,1794 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc0201906:	00006797          	auipc	a5,0x6
ffffffffc020190a:	b8b7b123          	sd	a1,-1150(a5) # ffffffffc0207488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020190e:	c02007b7          	lui	a5,0xc0200
ffffffffc0201912:	0af5e363          	bltu	a1,a5,ffffffffc02019b8 <pmm_init+0x1c6>
ffffffffc0201916:	6090                	ld	a2,0(s1)
}
ffffffffc0201918:	7402                	ld	s0,32(sp)
ffffffffc020191a:	70a2                	ld	ra,40(sp)
ffffffffc020191c:	64e2                	ld	s1,24(sp)
ffffffffc020191e:	6942                	ld	s2,16(sp)
ffffffffc0201920:	69a2                	ld	s3,8(sp)
ffffffffc0201922:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201924:	40c58633          	sub	a2,a1,a2
ffffffffc0201928:	00006797          	auipc	a5,0x6
ffffffffc020192c:	b4c7bc23          	sd	a2,-1192(a5) # ffffffffc0207480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201930:	00001517          	auipc	a0,0x1
ffffffffc0201934:	55850513          	addi	a0,a0,1368 # ffffffffc0202e88 <best_fit_pmm_manager+0x140>
}
ffffffffc0201938:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020193a:	fc2fe06f          	j	ffffffffc02000fc <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020193e:	c8000637          	lui	a2,0xc8000
ffffffffc0201942:	bf05                	j	ffffffffc0201872 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201944:	6705                	lui	a4,0x1
ffffffffc0201946:	177d                	addi	a4,a4,-1
ffffffffc0201948:	96ba                	add	a3,a3,a4
ffffffffc020194a:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc020194c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201950:	02c7f063          	bgeu	a5,a2,ffffffffc0201970 <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc0201954:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201956:	fff80737          	lui	a4,0xfff80
ffffffffc020195a:	973e                	add	a4,a4,a5
ffffffffc020195c:	00271793          	slli	a5,a4,0x2
ffffffffc0201960:	97ba                	add	a5,a5,a4
ffffffffc0201962:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201964:	8d95                	sub	a1,a1,a3
ffffffffc0201966:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201968:	81b1                	srli	a1,a1,0xc
ffffffffc020196a:	953e                	add	a0,a0,a5
ffffffffc020196c:	9702                	jalr	a4
}
ffffffffc020196e:	bfbd                	j	ffffffffc02018ec <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc0201970:	00001617          	auipc	a2,0x1
ffffffffc0201974:	4c860613          	addi	a2,a2,1224 # ffffffffc0202e38 <best_fit_pmm_manager+0xf0>
ffffffffc0201978:	06b00593          	li	a1,107
ffffffffc020197c:	00001517          	auipc	a0,0x1
ffffffffc0201980:	4dc50513          	addi	a0,a0,1244 # ffffffffc0202e58 <best_fit_pmm_manager+0x110>
ffffffffc0201984:	a73fe0ef          	jal	ra,ffffffffc02003f6 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201988:	00001617          	auipc	a2,0x1
ffffffffc020198c:	48860613          	addi	a2,a2,1160 # ffffffffc0202e10 <best_fit_pmm_manager+0xc8>
ffffffffc0201990:	07100593          	li	a1,113
ffffffffc0201994:	00001517          	auipc	a0,0x1
ffffffffc0201998:	42450513          	addi	a0,a0,1060 # ffffffffc0202db8 <best_fit_pmm_manager+0x70>
ffffffffc020199c:	a5bfe0ef          	jal	ra,ffffffffc02003f6 <__panic>
        panic("DTB memory info not available");
ffffffffc02019a0:	00001617          	auipc	a2,0x1
ffffffffc02019a4:	3f860613          	addi	a2,a2,1016 # ffffffffc0202d98 <best_fit_pmm_manager+0x50>
ffffffffc02019a8:	05a00593          	li	a1,90
ffffffffc02019ac:	00001517          	auipc	a0,0x1
ffffffffc02019b0:	40c50513          	addi	a0,a0,1036 # ffffffffc0202db8 <best_fit_pmm_manager+0x70>
ffffffffc02019b4:	a43fe0ef          	jal	ra,ffffffffc02003f6 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02019b8:	86ae                	mv	a3,a1
ffffffffc02019ba:	00001617          	auipc	a2,0x1
ffffffffc02019be:	45660613          	addi	a2,a2,1110 # ffffffffc0202e10 <best_fit_pmm_manager+0xc8>
ffffffffc02019c2:	08c00593          	li	a1,140
ffffffffc02019c6:	00001517          	auipc	a0,0x1
ffffffffc02019ca:	3f250513          	addi	a0,a0,1010 # ffffffffc0202db8 <best_fit_pmm_manager+0x70>
ffffffffc02019ce:	a29fe0ef          	jal	ra,ffffffffc02003f6 <__panic>

ffffffffc02019d2 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02019d2:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019d6:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02019d8:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019dc:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02019de:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019e2:	f022                	sd	s0,32(sp)
ffffffffc02019e4:	ec26                	sd	s1,24(sp)
ffffffffc02019e6:	e84a                	sd	s2,16(sp)
ffffffffc02019e8:	f406                	sd	ra,40(sp)
ffffffffc02019ea:	e44e                	sd	s3,8(sp)
ffffffffc02019ec:	84aa                	mv	s1,a0
ffffffffc02019ee:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02019f0:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02019f4:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02019f6:	03067e63          	bgeu	a2,a6,ffffffffc0201a32 <printnum+0x60>
ffffffffc02019fa:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02019fc:	00805763          	blez	s0,ffffffffc0201a0a <printnum+0x38>
ffffffffc0201a00:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201a02:	85ca                	mv	a1,s2
ffffffffc0201a04:	854e                	mv	a0,s3
ffffffffc0201a06:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201a08:	fc65                	bnez	s0,ffffffffc0201a00 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a0a:	1a02                	slli	s4,s4,0x20
ffffffffc0201a0c:	00001797          	auipc	a5,0x1
ffffffffc0201a10:	4bc78793          	addi	a5,a5,1212 # ffffffffc0202ec8 <best_fit_pmm_manager+0x180>
ffffffffc0201a14:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201a18:	9a3e                	add	s4,s4,a5
}
ffffffffc0201a1a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a1c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201a20:	70a2                	ld	ra,40(sp)
ffffffffc0201a22:	69a2                	ld	s3,8(sp)
ffffffffc0201a24:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a26:	85ca                	mv	a1,s2
ffffffffc0201a28:	87a6                	mv	a5,s1
}
ffffffffc0201a2a:	6942                	ld	s2,16(sp)
ffffffffc0201a2c:	64e2                	ld	s1,24(sp)
ffffffffc0201a2e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a30:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201a32:	03065633          	divu	a2,a2,a6
ffffffffc0201a36:	8722                	mv	a4,s0
ffffffffc0201a38:	f9bff0ef          	jal	ra,ffffffffc02019d2 <printnum>
ffffffffc0201a3c:	b7f9                	j	ffffffffc0201a0a <printnum+0x38>

ffffffffc0201a3e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201a3e:	7119                	addi	sp,sp,-128
ffffffffc0201a40:	f4a6                	sd	s1,104(sp)
ffffffffc0201a42:	f0ca                	sd	s2,96(sp)
ffffffffc0201a44:	ecce                	sd	s3,88(sp)
ffffffffc0201a46:	e8d2                	sd	s4,80(sp)
ffffffffc0201a48:	e4d6                	sd	s5,72(sp)
ffffffffc0201a4a:	e0da                	sd	s6,64(sp)
ffffffffc0201a4c:	fc5e                	sd	s7,56(sp)
ffffffffc0201a4e:	f06a                	sd	s10,32(sp)
ffffffffc0201a50:	fc86                	sd	ra,120(sp)
ffffffffc0201a52:	f8a2                	sd	s0,112(sp)
ffffffffc0201a54:	f862                	sd	s8,48(sp)
ffffffffc0201a56:	f466                	sd	s9,40(sp)
ffffffffc0201a58:	ec6e                	sd	s11,24(sp)
ffffffffc0201a5a:	892a                	mv	s2,a0
ffffffffc0201a5c:	84ae                	mv	s1,a1
ffffffffc0201a5e:	8d32                	mv	s10,a2
ffffffffc0201a60:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a62:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201a66:	5b7d                	li	s6,-1
ffffffffc0201a68:	00001a97          	auipc	s5,0x1
ffffffffc0201a6c:	494a8a93          	addi	s5,s5,1172 # ffffffffc0202efc <best_fit_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201a70:	00001b97          	auipc	s7,0x1
ffffffffc0201a74:	668b8b93          	addi	s7,s7,1640 # ffffffffc02030d8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a78:	000d4503          	lbu	a0,0(s10)
ffffffffc0201a7c:	001d0413          	addi	s0,s10,1
ffffffffc0201a80:	01350a63          	beq	a0,s3,ffffffffc0201a94 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201a84:	c121                	beqz	a0,ffffffffc0201ac4 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201a86:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a88:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201a8a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a8c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201a90:	ff351ae3          	bne	a0,s3,ffffffffc0201a84 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a94:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201a98:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201a9c:	4c81                	li	s9,0
ffffffffc0201a9e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201aa0:	5c7d                	li	s8,-1
ffffffffc0201aa2:	5dfd                	li	s11,-1
ffffffffc0201aa4:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201aa8:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201aaa:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201aae:	0ff5f593          	zext.b	a1,a1
ffffffffc0201ab2:	00140d13          	addi	s10,s0,1
ffffffffc0201ab6:	04b56263          	bltu	a0,a1,ffffffffc0201afa <vprintfmt+0xbc>
ffffffffc0201aba:	058a                	slli	a1,a1,0x2
ffffffffc0201abc:	95d6                	add	a1,a1,s5
ffffffffc0201abe:	4194                	lw	a3,0(a1)
ffffffffc0201ac0:	96d6                	add	a3,a3,s5
ffffffffc0201ac2:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201ac4:	70e6                	ld	ra,120(sp)
ffffffffc0201ac6:	7446                	ld	s0,112(sp)
ffffffffc0201ac8:	74a6                	ld	s1,104(sp)
ffffffffc0201aca:	7906                	ld	s2,96(sp)
ffffffffc0201acc:	69e6                	ld	s3,88(sp)
ffffffffc0201ace:	6a46                	ld	s4,80(sp)
ffffffffc0201ad0:	6aa6                	ld	s5,72(sp)
ffffffffc0201ad2:	6b06                	ld	s6,64(sp)
ffffffffc0201ad4:	7be2                	ld	s7,56(sp)
ffffffffc0201ad6:	7c42                	ld	s8,48(sp)
ffffffffc0201ad8:	7ca2                	ld	s9,40(sp)
ffffffffc0201ada:	7d02                	ld	s10,32(sp)
ffffffffc0201adc:	6de2                	ld	s11,24(sp)
ffffffffc0201ade:	6109                	addi	sp,sp,128
ffffffffc0201ae0:	8082                	ret
            padc = '0';
ffffffffc0201ae2:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201ae4:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ae8:	846a                	mv	s0,s10
ffffffffc0201aea:	00140d13          	addi	s10,s0,1
ffffffffc0201aee:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201af2:	0ff5f593          	zext.b	a1,a1
ffffffffc0201af6:	fcb572e3          	bgeu	a0,a1,ffffffffc0201aba <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201afa:	85a6                	mv	a1,s1
ffffffffc0201afc:	02500513          	li	a0,37
ffffffffc0201b00:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201b02:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201b06:	8d22                	mv	s10,s0
ffffffffc0201b08:	f73788e3          	beq	a5,s3,ffffffffc0201a78 <vprintfmt+0x3a>
ffffffffc0201b0c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201b10:	1d7d                	addi	s10,s10,-1
ffffffffc0201b12:	ff379de3          	bne	a5,s3,ffffffffc0201b0c <vprintfmt+0xce>
ffffffffc0201b16:	b78d                	j	ffffffffc0201a78 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201b18:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201b1c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b20:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201b22:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201b26:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b2a:	02d86463          	bltu	a6,a3,ffffffffc0201b52 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201b2e:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201b32:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201b36:	0186873b          	addw	a4,a3,s8
ffffffffc0201b3a:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201b3e:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201b40:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201b44:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201b46:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201b4a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b4e:	fed870e3          	bgeu	a6,a3,ffffffffc0201b2e <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201b52:	f40ddce3          	bgez	s11,ffffffffc0201aaa <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201b56:	8de2                	mv	s11,s8
ffffffffc0201b58:	5c7d                	li	s8,-1
ffffffffc0201b5a:	bf81                	j	ffffffffc0201aaa <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201b5c:	fffdc693          	not	a3,s11
ffffffffc0201b60:	96fd                	srai	a3,a3,0x3f
ffffffffc0201b62:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b66:	00144603          	lbu	a2,1(s0)
ffffffffc0201b6a:	2d81                	sext.w	s11,s11
ffffffffc0201b6c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b6e:	bf35                	j	ffffffffc0201aaa <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201b70:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b74:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201b78:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b7a:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201b7c:	bfd9                	j	ffffffffc0201b52 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201b7e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b80:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b84:	01174463          	blt	a4,a7,ffffffffc0201b8c <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201b88:	1a088e63          	beqz	a7,ffffffffc0201d44 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201b8c:	000a3603          	ld	a2,0(s4)
ffffffffc0201b90:	46c1                	li	a3,16
ffffffffc0201b92:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201b94:	2781                	sext.w	a5,a5
ffffffffc0201b96:	876e                	mv	a4,s11
ffffffffc0201b98:	85a6                	mv	a1,s1
ffffffffc0201b9a:	854a                	mv	a0,s2
ffffffffc0201b9c:	e37ff0ef          	jal	ra,ffffffffc02019d2 <printnum>
            break;
ffffffffc0201ba0:	bde1                	j	ffffffffc0201a78 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201ba2:	000a2503          	lw	a0,0(s4)
ffffffffc0201ba6:	85a6                	mv	a1,s1
ffffffffc0201ba8:	0a21                	addi	s4,s4,8
ffffffffc0201baa:	9902                	jalr	s2
            break;
ffffffffc0201bac:	b5f1                	j	ffffffffc0201a78 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201bae:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201bb0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201bb4:	01174463          	blt	a4,a7,ffffffffc0201bbc <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201bb8:	18088163          	beqz	a7,ffffffffc0201d3a <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201bbc:	000a3603          	ld	a2,0(s4)
ffffffffc0201bc0:	46a9                	li	a3,10
ffffffffc0201bc2:	8a2e                	mv	s4,a1
ffffffffc0201bc4:	bfc1                	j	ffffffffc0201b94 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bc6:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201bca:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bcc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201bce:	bdf1                	j	ffffffffc0201aaa <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201bd0:	85a6                	mv	a1,s1
ffffffffc0201bd2:	02500513          	li	a0,37
ffffffffc0201bd6:	9902                	jalr	s2
            break;
ffffffffc0201bd8:	b545                	j	ffffffffc0201a78 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bda:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201bde:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201be0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201be2:	b5e1                	j	ffffffffc0201aaa <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201be4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201be6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201bea:	01174463          	blt	a4,a7,ffffffffc0201bf2 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201bee:	14088163          	beqz	a7,ffffffffc0201d30 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201bf2:	000a3603          	ld	a2,0(s4)
ffffffffc0201bf6:	46a1                	li	a3,8
ffffffffc0201bf8:	8a2e                	mv	s4,a1
ffffffffc0201bfa:	bf69                	j	ffffffffc0201b94 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201bfc:	03000513          	li	a0,48
ffffffffc0201c00:	85a6                	mv	a1,s1
ffffffffc0201c02:	e03e                	sd	a5,0(sp)
ffffffffc0201c04:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201c06:	85a6                	mv	a1,s1
ffffffffc0201c08:	07800513          	li	a0,120
ffffffffc0201c0c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c0e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201c10:	6782                	ld	a5,0(sp)
ffffffffc0201c12:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c14:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201c18:	bfb5                	j	ffffffffc0201b94 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c1a:	000a3403          	ld	s0,0(s4)
ffffffffc0201c1e:	008a0713          	addi	a4,s4,8
ffffffffc0201c22:	e03a                	sd	a4,0(sp)
ffffffffc0201c24:	14040263          	beqz	s0,ffffffffc0201d68 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201c28:	0fb05763          	blez	s11,ffffffffc0201d16 <vprintfmt+0x2d8>
ffffffffc0201c2c:	02d00693          	li	a3,45
ffffffffc0201c30:	0cd79163          	bne	a5,a3,ffffffffc0201cf2 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c34:	00044783          	lbu	a5,0(s0)
ffffffffc0201c38:	0007851b          	sext.w	a0,a5
ffffffffc0201c3c:	cf85                	beqz	a5,ffffffffc0201c74 <vprintfmt+0x236>
ffffffffc0201c3e:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c42:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c46:	000c4563          	bltz	s8,ffffffffc0201c50 <vprintfmt+0x212>
ffffffffc0201c4a:	3c7d                	addiw	s8,s8,-1
ffffffffc0201c4c:	036c0263          	beq	s8,s6,ffffffffc0201c70 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201c50:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c52:	0e0c8e63          	beqz	s9,ffffffffc0201d4e <vprintfmt+0x310>
ffffffffc0201c56:	3781                	addiw	a5,a5,-32
ffffffffc0201c58:	0ef47b63          	bgeu	s0,a5,ffffffffc0201d4e <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201c5c:	03f00513          	li	a0,63
ffffffffc0201c60:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c62:	000a4783          	lbu	a5,0(s4)
ffffffffc0201c66:	3dfd                	addiw	s11,s11,-1
ffffffffc0201c68:	0a05                	addi	s4,s4,1
ffffffffc0201c6a:	0007851b          	sext.w	a0,a5
ffffffffc0201c6e:	ffe1                	bnez	a5,ffffffffc0201c46 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201c70:	01b05963          	blez	s11,ffffffffc0201c82 <vprintfmt+0x244>
ffffffffc0201c74:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201c76:	85a6                	mv	a1,s1
ffffffffc0201c78:	02000513          	li	a0,32
ffffffffc0201c7c:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201c7e:	fe0d9be3          	bnez	s11,ffffffffc0201c74 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c82:	6a02                	ld	s4,0(sp)
ffffffffc0201c84:	bbd5                	j	ffffffffc0201a78 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c86:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c88:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201c8c:	01174463          	blt	a4,a7,ffffffffc0201c94 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201c90:	08088d63          	beqz	a7,ffffffffc0201d2a <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201c94:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201c98:	0a044d63          	bltz	s0,ffffffffc0201d52 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201c9c:	8622                	mv	a2,s0
ffffffffc0201c9e:	8a66                	mv	s4,s9
ffffffffc0201ca0:	46a9                	li	a3,10
ffffffffc0201ca2:	bdcd                	j	ffffffffc0201b94 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201ca4:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201ca8:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201caa:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201cac:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201cb0:	8fb5                	xor	a5,a5,a3
ffffffffc0201cb2:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201cb6:	02d74163          	blt	a4,a3,ffffffffc0201cd8 <vprintfmt+0x29a>
ffffffffc0201cba:	00369793          	slli	a5,a3,0x3
ffffffffc0201cbe:	97de                	add	a5,a5,s7
ffffffffc0201cc0:	639c                	ld	a5,0(a5)
ffffffffc0201cc2:	cb99                	beqz	a5,ffffffffc0201cd8 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201cc4:	86be                	mv	a3,a5
ffffffffc0201cc6:	00001617          	auipc	a2,0x1
ffffffffc0201cca:	23260613          	addi	a2,a2,562 # ffffffffc0202ef8 <best_fit_pmm_manager+0x1b0>
ffffffffc0201cce:	85a6                	mv	a1,s1
ffffffffc0201cd0:	854a                	mv	a0,s2
ffffffffc0201cd2:	0ce000ef          	jal	ra,ffffffffc0201da0 <printfmt>
ffffffffc0201cd6:	b34d                	j	ffffffffc0201a78 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201cd8:	00001617          	auipc	a2,0x1
ffffffffc0201cdc:	21060613          	addi	a2,a2,528 # ffffffffc0202ee8 <best_fit_pmm_manager+0x1a0>
ffffffffc0201ce0:	85a6                	mv	a1,s1
ffffffffc0201ce2:	854a                	mv	a0,s2
ffffffffc0201ce4:	0bc000ef          	jal	ra,ffffffffc0201da0 <printfmt>
ffffffffc0201ce8:	bb41                	j	ffffffffc0201a78 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201cea:	00001417          	auipc	s0,0x1
ffffffffc0201cee:	1f640413          	addi	s0,s0,502 # ffffffffc0202ee0 <best_fit_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cf2:	85e2                	mv	a1,s8
ffffffffc0201cf4:	8522                	mv	a0,s0
ffffffffc0201cf6:	e43e                	sd	a5,8(sp)
ffffffffc0201cf8:	200000ef          	jal	ra,ffffffffc0201ef8 <strnlen>
ffffffffc0201cfc:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201d00:	01b05b63          	blez	s11,ffffffffc0201d16 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201d04:	67a2                	ld	a5,8(sp)
ffffffffc0201d06:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d0a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201d0c:	85a6                	mv	a1,s1
ffffffffc0201d0e:	8552                	mv	a0,s4
ffffffffc0201d10:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d12:	fe0d9ce3          	bnez	s11,ffffffffc0201d0a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d16:	00044783          	lbu	a5,0(s0)
ffffffffc0201d1a:	00140a13          	addi	s4,s0,1
ffffffffc0201d1e:	0007851b          	sext.w	a0,a5
ffffffffc0201d22:	d3a5                	beqz	a5,ffffffffc0201c82 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d24:	05e00413          	li	s0,94
ffffffffc0201d28:	bf39                	j	ffffffffc0201c46 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201d2a:	000a2403          	lw	s0,0(s4)
ffffffffc0201d2e:	b7ad                	j	ffffffffc0201c98 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201d30:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d34:	46a1                	li	a3,8
ffffffffc0201d36:	8a2e                	mv	s4,a1
ffffffffc0201d38:	bdb1                	j	ffffffffc0201b94 <vprintfmt+0x156>
ffffffffc0201d3a:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d3e:	46a9                	li	a3,10
ffffffffc0201d40:	8a2e                	mv	s4,a1
ffffffffc0201d42:	bd89                	j	ffffffffc0201b94 <vprintfmt+0x156>
ffffffffc0201d44:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d48:	46c1                	li	a3,16
ffffffffc0201d4a:	8a2e                	mv	s4,a1
ffffffffc0201d4c:	b5a1                	j	ffffffffc0201b94 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201d4e:	9902                	jalr	s2
ffffffffc0201d50:	bf09                	j	ffffffffc0201c62 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201d52:	85a6                	mv	a1,s1
ffffffffc0201d54:	02d00513          	li	a0,45
ffffffffc0201d58:	e03e                	sd	a5,0(sp)
ffffffffc0201d5a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201d5c:	6782                	ld	a5,0(sp)
ffffffffc0201d5e:	8a66                	mv	s4,s9
ffffffffc0201d60:	40800633          	neg	a2,s0
ffffffffc0201d64:	46a9                	li	a3,10
ffffffffc0201d66:	b53d                	j	ffffffffc0201b94 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201d68:	03b05163          	blez	s11,ffffffffc0201d8a <vprintfmt+0x34c>
ffffffffc0201d6c:	02d00693          	li	a3,45
ffffffffc0201d70:	f6d79de3          	bne	a5,a3,ffffffffc0201cea <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201d74:	00001417          	auipc	s0,0x1
ffffffffc0201d78:	16c40413          	addi	s0,s0,364 # ffffffffc0202ee0 <best_fit_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d7c:	02800793          	li	a5,40
ffffffffc0201d80:	02800513          	li	a0,40
ffffffffc0201d84:	00140a13          	addi	s4,s0,1
ffffffffc0201d88:	bd6d                	j	ffffffffc0201c42 <vprintfmt+0x204>
ffffffffc0201d8a:	00001a17          	auipc	s4,0x1
ffffffffc0201d8e:	157a0a13          	addi	s4,s4,343 # ffffffffc0202ee1 <best_fit_pmm_manager+0x199>
ffffffffc0201d92:	02800513          	li	a0,40
ffffffffc0201d96:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d9a:	05e00413          	li	s0,94
ffffffffc0201d9e:	b565                	j	ffffffffc0201c46 <vprintfmt+0x208>

ffffffffc0201da0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201da0:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201da2:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201da6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201da8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201daa:	ec06                	sd	ra,24(sp)
ffffffffc0201dac:	f83a                	sd	a4,48(sp)
ffffffffc0201dae:	fc3e                	sd	a5,56(sp)
ffffffffc0201db0:	e0c2                	sd	a6,64(sp)
ffffffffc0201db2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201db4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201db6:	c89ff0ef          	jal	ra,ffffffffc0201a3e <vprintfmt>
}
ffffffffc0201dba:	60e2                	ld	ra,24(sp)
ffffffffc0201dbc:	6161                	addi	sp,sp,80
ffffffffc0201dbe:	8082                	ret

ffffffffc0201dc0 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201dc0:	715d                	addi	sp,sp,-80
ffffffffc0201dc2:	e486                	sd	ra,72(sp)
ffffffffc0201dc4:	e0a6                	sd	s1,64(sp)
ffffffffc0201dc6:	fc4a                	sd	s2,56(sp)
ffffffffc0201dc8:	f84e                	sd	s3,48(sp)
ffffffffc0201dca:	f452                	sd	s4,40(sp)
ffffffffc0201dcc:	f056                	sd	s5,32(sp)
ffffffffc0201dce:	ec5a                	sd	s6,24(sp)
ffffffffc0201dd0:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201dd2:	c901                	beqz	a0,ffffffffc0201de2 <readline+0x22>
ffffffffc0201dd4:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201dd6:	00001517          	auipc	a0,0x1
ffffffffc0201dda:	12250513          	addi	a0,a0,290 # ffffffffc0202ef8 <best_fit_pmm_manager+0x1b0>
ffffffffc0201dde:	b1efe0ef          	jal	ra,ffffffffc02000fc <cprintf>
readline(const char *prompt) {
ffffffffc0201de2:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201de4:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201de6:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201de8:	4aa9                	li	s5,10
ffffffffc0201dea:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201dec:	00005b97          	auipc	s7,0x5
ffffffffc0201df0:	254b8b93          	addi	s7,s7,596 # ffffffffc0207040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201df4:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201df8:	b7cfe0ef          	jal	ra,ffffffffc0200174 <getchar>
        if (c < 0) {
ffffffffc0201dfc:	00054a63          	bltz	a0,ffffffffc0201e10 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e00:	00a95a63          	bge	s2,a0,ffffffffc0201e14 <readline+0x54>
ffffffffc0201e04:	029a5263          	bge	s4,s1,ffffffffc0201e28 <readline+0x68>
        c = getchar();
ffffffffc0201e08:	b6cfe0ef          	jal	ra,ffffffffc0200174 <getchar>
        if (c < 0) {
ffffffffc0201e0c:	fe055ae3          	bgez	a0,ffffffffc0201e00 <readline+0x40>
            return NULL;
ffffffffc0201e10:	4501                	li	a0,0
ffffffffc0201e12:	a091                	j	ffffffffc0201e56 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201e14:	03351463          	bne	a0,s3,ffffffffc0201e3c <readline+0x7c>
ffffffffc0201e18:	e8a9                	bnez	s1,ffffffffc0201e6a <readline+0xaa>
        c = getchar();
ffffffffc0201e1a:	b5afe0ef          	jal	ra,ffffffffc0200174 <getchar>
        if (c < 0) {
ffffffffc0201e1e:	fe0549e3          	bltz	a0,ffffffffc0201e10 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e22:	fea959e3          	bge	s2,a0,ffffffffc0201e14 <readline+0x54>
ffffffffc0201e26:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201e28:	e42a                	sd	a0,8(sp)
ffffffffc0201e2a:	b08fe0ef          	jal	ra,ffffffffc0200132 <cputchar>
            buf[i ++] = c;
ffffffffc0201e2e:	6522                	ld	a0,8(sp)
ffffffffc0201e30:	009b87b3          	add	a5,s7,s1
ffffffffc0201e34:	2485                	addiw	s1,s1,1
ffffffffc0201e36:	00a78023          	sb	a0,0(a5)
ffffffffc0201e3a:	bf7d                	j	ffffffffc0201df8 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201e3c:	01550463          	beq	a0,s5,ffffffffc0201e44 <readline+0x84>
ffffffffc0201e40:	fb651ce3          	bne	a0,s6,ffffffffc0201df8 <readline+0x38>
            cputchar(c);
ffffffffc0201e44:	aeefe0ef          	jal	ra,ffffffffc0200132 <cputchar>
            buf[i] = '\0';
ffffffffc0201e48:	00005517          	auipc	a0,0x5
ffffffffc0201e4c:	1f850513          	addi	a0,a0,504 # ffffffffc0207040 <buf>
ffffffffc0201e50:	94aa                	add	s1,s1,a0
ffffffffc0201e52:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201e56:	60a6                	ld	ra,72(sp)
ffffffffc0201e58:	6486                	ld	s1,64(sp)
ffffffffc0201e5a:	7962                	ld	s2,56(sp)
ffffffffc0201e5c:	79c2                	ld	s3,48(sp)
ffffffffc0201e5e:	7a22                	ld	s4,40(sp)
ffffffffc0201e60:	7a82                	ld	s5,32(sp)
ffffffffc0201e62:	6b62                	ld	s6,24(sp)
ffffffffc0201e64:	6bc2                	ld	s7,16(sp)
ffffffffc0201e66:	6161                	addi	sp,sp,80
ffffffffc0201e68:	8082                	ret
            cputchar(c);
ffffffffc0201e6a:	4521                	li	a0,8
ffffffffc0201e6c:	ac6fe0ef          	jal	ra,ffffffffc0200132 <cputchar>
            i --;
ffffffffc0201e70:	34fd                	addiw	s1,s1,-1
ffffffffc0201e72:	b759                	j	ffffffffc0201df8 <readline+0x38>

ffffffffc0201e74 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201e74:	4781                	li	a5,0
ffffffffc0201e76:	00005717          	auipc	a4,0x5
ffffffffc0201e7a:	1a273703          	ld	a4,418(a4) # ffffffffc0207018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201e7e:	88ba                	mv	a7,a4
ffffffffc0201e80:	852a                	mv	a0,a0
ffffffffc0201e82:	85be                	mv	a1,a5
ffffffffc0201e84:	863e                	mv	a2,a5
ffffffffc0201e86:	00000073          	ecall
ffffffffc0201e8a:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201e8c:	8082                	ret

ffffffffc0201e8e <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201e8e:	4781                	li	a5,0
ffffffffc0201e90:	00005717          	auipc	a4,0x5
ffffffffc0201e94:	60873703          	ld	a4,1544(a4) # ffffffffc0207498 <SBI_SET_TIMER>
ffffffffc0201e98:	88ba                	mv	a7,a4
ffffffffc0201e9a:	852a                	mv	a0,a0
ffffffffc0201e9c:	85be                	mv	a1,a5
ffffffffc0201e9e:	863e                	mv	a2,a5
ffffffffc0201ea0:	00000073          	ecall
ffffffffc0201ea4:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201ea6:	8082                	ret

ffffffffc0201ea8 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201ea8:	4501                	li	a0,0
ffffffffc0201eaa:	00005797          	auipc	a5,0x5
ffffffffc0201eae:	1667b783          	ld	a5,358(a5) # ffffffffc0207010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201eb2:	88be                	mv	a7,a5
ffffffffc0201eb4:	852a                	mv	a0,a0
ffffffffc0201eb6:	85aa                	mv	a1,a0
ffffffffc0201eb8:	862a                	mv	a2,a0
ffffffffc0201eba:	00000073          	ecall
ffffffffc0201ebe:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201ec0:	2501                	sext.w	a0,a0
ffffffffc0201ec2:	8082                	ret

ffffffffc0201ec4 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201ec4:	4781                	li	a5,0
ffffffffc0201ec6:	00005717          	auipc	a4,0x5
ffffffffc0201eca:	15a73703          	ld	a4,346(a4) # ffffffffc0207020 <SBI_SHUTDOWN>
ffffffffc0201ece:	88ba                	mv	a7,a4
ffffffffc0201ed0:	853e                	mv	a0,a5
ffffffffc0201ed2:	85be                	mv	a1,a5
ffffffffc0201ed4:	863e                	mv	a2,a5
ffffffffc0201ed6:	00000073          	ecall
ffffffffc0201eda:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201edc:	8082                	ret

ffffffffc0201ede <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201ede:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201ee2:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201ee4:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201ee6:	cb81                	beqz	a5,ffffffffc0201ef6 <strlen+0x18>
        cnt ++;
ffffffffc0201ee8:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201eea:	00a707b3          	add	a5,a4,a0
ffffffffc0201eee:	0007c783          	lbu	a5,0(a5)
ffffffffc0201ef2:	fbfd                	bnez	a5,ffffffffc0201ee8 <strlen+0xa>
ffffffffc0201ef4:	8082                	ret
    }
    return cnt;
}
ffffffffc0201ef6:	8082                	ret

ffffffffc0201ef8 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201ef8:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201efa:	e589                	bnez	a1,ffffffffc0201f04 <strnlen+0xc>
ffffffffc0201efc:	a811                	j	ffffffffc0201f10 <strnlen+0x18>
        cnt ++;
ffffffffc0201efe:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f00:	00f58863          	beq	a1,a5,ffffffffc0201f10 <strnlen+0x18>
ffffffffc0201f04:	00f50733          	add	a4,a0,a5
ffffffffc0201f08:	00074703          	lbu	a4,0(a4)
ffffffffc0201f0c:	fb6d                	bnez	a4,ffffffffc0201efe <strnlen+0x6>
ffffffffc0201f0e:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201f10:	852e                	mv	a0,a1
ffffffffc0201f12:	8082                	ret

ffffffffc0201f14 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f14:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f18:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f1c:	cb89                	beqz	a5,ffffffffc0201f2e <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201f1e:	0505                	addi	a0,a0,1
ffffffffc0201f20:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f22:	fee789e3          	beq	a5,a4,ffffffffc0201f14 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f26:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201f2a:	9d19                	subw	a0,a0,a4
ffffffffc0201f2c:	8082                	ret
ffffffffc0201f2e:	4501                	li	a0,0
ffffffffc0201f30:	bfed                	j	ffffffffc0201f2a <strcmp+0x16>

ffffffffc0201f32 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f32:	c20d                	beqz	a2,ffffffffc0201f54 <strncmp+0x22>
ffffffffc0201f34:	962e                	add	a2,a2,a1
ffffffffc0201f36:	a031                	j	ffffffffc0201f42 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201f38:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f3a:	00e79a63          	bne	a5,a4,ffffffffc0201f4e <strncmp+0x1c>
ffffffffc0201f3e:	00b60b63          	beq	a2,a1,ffffffffc0201f54 <strncmp+0x22>
ffffffffc0201f42:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201f46:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f48:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201f4c:	f7f5                	bnez	a5,ffffffffc0201f38 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f4e:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201f52:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f54:	4501                	li	a0,0
ffffffffc0201f56:	8082                	ret

ffffffffc0201f58 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201f58:	00054783          	lbu	a5,0(a0)
ffffffffc0201f5c:	c799                	beqz	a5,ffffffffc0201f6a <strchr+0x12>
        if (*s == c) {
ffffffffc0201f5e:	00f58763          	beq	a1,a5,ffffffffc0201f6c <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201f62:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201f66:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201f68:	fbfd                	bnez	a5,ffffffffc0201f5e <strchr+0x6>
    }
    return NULL;
ffffffffc0201f6a:	4501                	li	a0,0
}
ffffffffc0201f6c:	8082                	ret

ffffffffc0201f6e <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201f6e:	ca01                	beqz	a2,ffffffffc0201f7e <memset+0x10>
ffffffffc0201f70:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201f72:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201f74:	0785                	addi	a5,a5,1
ffffffffc0201f76:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201f7a:	fec79de3          	bne	a5,a2,ffffffffc0201f74 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201f7e:	8082                	ret
