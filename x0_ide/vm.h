#ifdef __cplusplus

extern "C" {

#endif

#ifndef __VM_H__

#define __VM_H__

#include <stdio.h>

#define VM_INST_MAX 5000 /* 虚拟机指令上限 */
#define VM_STACK_MAX 50000 /* 虚拟机栈上限 */
#define VM_MNE_N 21 /* 虚拟机助记符数量 */

#define I2F(x) (*((float*)&(x)))
#define F2I(x) (*((int*)&(x)))

/* 虚拟机指令助记符： 指令集已经重新设计 */
enum mne {
    lod, lit, sto, cal, ini, jmp, jpc, // opr指令被全面拆分
    wrt, red, // 按类型输入/输出指令，将数存放到栈顶或从栈顶输出
    arti, artf, // 按类型的算术指令（加减乘除，取模）
    log, // 逻辑运算指令
    bit, // 位运算指令
    cmpi, cmpf, // 按类型的比较指令
    cvt, // 将int和float互相转换的指令
    pop, // 弹出栈/偏移量栈栈顶的指令，用于翻译赋值表达式和数组寻址
    mov, // 将栈顶元素移入偏移量栈
    lodr, stor, // 利用偏移量栈，用于进行数组寻址
    adr // 将栈顶地址放入栈中，用于实现switch-case语句
};
extern char* mne_str[VM_MNE_N];

/* 虚拟机代码结构: 不存在过程嵌套，不再使用层次差 */
struct inst_t {
	enum mne m;   /* 虚拟机代码指令 */
	int a;        /* 指令参数 */
};
struct inst_t vcode[VM_INST_MAX]; /* 存放虚拟机代码的数组 */
int code_cnt; /* 虚拟机指令数量 */
int cur; /* 当前指令下标 */

int stack[VM_STACK_MAX]; /* 虚拟机的栈，每个数据均占4字节；由于不存在嵌套，每个过程的栈帧不包括静态链，仅包括动态链、返回地址 */
int off_stk[VM_INST_MAX], os_top; /* 偏移量栈及其栈顶指针，供处理数组所用 */
int base, top; /* 当前过程基址，栈顶下标 */

void vm_init(); /* 初始化虚拟机 */
void vm_load_ins(FILE* inf); /* 将指令文件载入虚拟机中 */
void vm_save_ins(FILE* outf); /* 将虚拟机中的指令保存到文件中 */
void vm_step(FILE* inf, char* outs); /* 单步执行当前指令 */

#endif

#ifdef __cplusplus

}

#endif
