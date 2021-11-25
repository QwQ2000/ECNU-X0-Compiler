#ifndef __VM_H__

#define __VM_H__

#define VM_INST_MAX 5000 /* 虚拟机指令上限 */

/* 虚拟机指令助记符： 指令集已经重新设计 */
enum mne {
    lod, sto, cal, ini, jmp, jpc, // lit指令被整合进lod中，0x……十六进制形式为常量，十进制形式为变量； opr指令被全面拆分
    wti, wtc, wtb, wtf, // 按类型输出指令
    rdi, rdc, rdb, rdf, // 按类型读入指令
    addi, addf, subi, subf, 
    muli, mulf, divi, divf, // 按类型（栈顶的操作数）四则运算指令
    andl, orl, notl, // 逻辑运算指令
    andb, orb, notb, xorb, shl, shr, // 位运算指令
    mod, // 取模指令
};

/* 虚拟机代码结构: 不存在过程嵌套，不再使用层次差 */
struct inst_t {
	enum mne m;   /* 虚拟机代码指令 */
	int a;        /* 指令参数 */
};
struct inst_t vm_code[VM_INST_MAX]; /* 存放虚拟机代码的数组 */

int vm_p; /* 虚拟机指令指针 */

#endif