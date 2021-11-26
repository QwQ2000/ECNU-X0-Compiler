#include "vm.h"
#include <string.h>
#include <stdlib.h>

#define I2F(x) (*((float*)&(x)))
#define F2I(x) (*((int*)&(x)))

void vm_init() {
    cur = 0;
    base = 1;
    top = 3; // 0位置不用，1和2位置为主程序的动态链、返回地址

    memset(stack,0,sizeof(stack)); // 主程序的动态链、返回地址均为0
}

void vm_load_ins(FILE* inf) {
    int a;
    char buf[20];
    code_cnt = 0;
    while (fscanf(inf,"%s %d", buf, &a) == 2) {
        int m;
        for (m = 0;m < VM_MNE_N; ++m) 
            if (!strcmp(mne_str[m],buf))
                break;
        // 对于不存在的指令报错并退出
        if (m == VM_MNE_N) {
            printf("Invalid instruction at line %d!\n",code_cnt + 1);
            exit(1);
        }
        vcode[code_cnt].m = m;
        vcode[code_cnt++].a = a;
    }
}

void vm_save_ins(FILE* outf) {
    int i;
    for (i = 0;i < code_cnt;++i)
        fprintf(outf,"%s %d\n",mne_str[vcode[code_cnt].m],vcode[code_cnt].a);  
}

void vm_execute(FILE* inf, FILE* outf) {
    while (cur < code_cnt) {
        vm_step(inf, outf);
        /*for (int i=0;i<top;++i)
            printf("%d ",stack[i]);
        printf("\n");*/
    }
}

void vm_step(FILE* inf, FILE* outf) {
    struct inst_t i = vcode[cur];
    float tmp; // 存储浮点数中间运算的结果，内存原样复制到整形变量的空间中
    char c[2]; // 读入字符

    ++cur;
    switch (i.m) {
        case lod:
            stack[top] = stack[base + i.a];
            ++top;
            break;

        case lit:
            stack[top++] = i.a;
            break;

        case sto:
            stack[base + i.a] = stack[--top];
            break;

        case cal:
            stack[top++] = base;
            stack[top++] = cur;
            base = top - 2;
            cur = i.a;
            break;

        case ini:
            top += i.a;
            break;

        case jmp:
            cur = i.a;
            break;

        case jpc:
            if (!stack[top-- - 1])
                cur = i.a;
            break;

        case wrt: // 0,1,2,3 分别对应 int,char,bool,float
            switch (i.a) {
                case 0:
                    fprintf(outf, "%d", stack[--top]);
                    break;

                case 1:
                    fprintf(outf, "%c", stack[--top]);
                    break;

                case 2:           
                    fprintf(outf, stack[--top] ? "True" : "False");
                    break;

                case 3:
                    fprintf(outf, "%f", I2F(stack[--top])); // 用int数组储存float，内存排布相同，用float类型解释        
            }
            break;

        case red: // 0,1,2,3 分别对应 int,char,bool,float
            switch (i.a) {
                case 0:
                case 2: // 用整数来处理布尔型，0表示假，其他表示真
                    fscanf(inf, "%d", stack + top++);
                    break;

                case 1:
                    fscanf(inf, "%s", c);
                    stack[top++] = *c;
                    break;

                case 3:
                    fscanf(inf, "%f", (float*)(stack + top++)); // 用int数组储存float，内存排布相同，用float类型解释 s       
            }
            break;

        case arti: // 0,1,2,3,4 分别对应加减乘除和取模
            --top;
            switch (i.a) {
                case 0:
                    stack[top - 1] = stack[top] + stack[top - 1];
                    break;
                
                case 1:
                    stack[top - 1] = stack[top] - stack[top - 1];
                    break;
                
                case 2:
                    stack[top - 1] = stack[top] * stack[top - 1];
                    break;
                
                case 3:
                    stack[top - 1] = stack[top] / stack[top - 1];
                    break;
                
                case 4:
                    stack[top - 1] = stack[top] % stack[top - 1];
                    break;
            }
            break;

        case artf:
            --top;
            switch (i.a) {
                case 0:
                    tmp = I2F(stack[top]) + I2F(stack[top - 1]);
                    break;
                
                case 1:
                    tmp = I2F(stack[top]) - I2F(stack[top - 1]);
                    break;
                
                case 2:
                    tmp = I2F(stack[top]) * I2F(stack[top - 1]);
                    break;
                
                case 3:
                    tmp = I2F(stack[top]) / I2F(stack[top - 1]);
            }
            stack[top - 1] = F2I(tmp);
            break;

        case log: // 逻辑运算 0,1,2 分别表示 与，或，非
            switch (i.a) {
                case 0:
                    --top;
                    stack[top - 1] = stack[top] && stack[top - 1];
                    break;
                
                case 1:
                    --top;
                    stack[top - 1] = stack[top] || stack[top - 1];
                    break;
                
                case 2:
                    stack[top - 1] = !stack[top - 1];
            }
            break;

        case bit: // 位运算 0,1,2,3,4,5 分别表示 与，或，非，异或，左移，右移
            switch (i.a) {
                case 0:
                    --top;
                    stack[top - 1] = stack[top] & stack[top - 1];
                    break;
                
                case 1:
                    --top;
                    stack[top - 1] = stack[top] | stack[top - 1];
                    break;
                
                case 2:
                    stack[top - 1] = ~stack[top - 1];
                    break;
                
                case 3:
                    --top;
                    stack[top - 1] = stack[top] ^ stack[top - 1];
                    break;
                
                case 4:
                    --top;
                    stack[top - 1] = stack[top] << stack[top - 1];
                    break;
                
                case 5:
                    --top;
                    stack[top - 1] = stack[top] >> stack[top - 1];
            }
            break;

        case cmpi: // 0,1,2,3,4 分别对应 ==,<,<=,>,>=
            --top;
            switch (i.a) {
                case 0:
                    stack[top - 1] = (stack[top] == stack[top - 1]);
                    break;
                
                case 1:
                    stack[top - 1] = (stack[top] < stack[top - 1]);
                    break;
                
                case 2:
                    stack[top - 1] = (stack[top] <= stack[top - 1]);
                    break;
                
                case 3:
                    stack[top - 1] = (stack[top] > stack[top - 1]);
                    break;
                
                case 4:
                    stack[top - 1] = (stack[top] >= stack[top - 1]);
            }
            break;
        
        case cmpf:
            --top;
            switch (i.a) {
                case 0:
                    stack[top - 1] = (I2F(stack[top]) == I2F(stack[top - 1]));
                    break;
                
                case 1:
                    stack[top - 1] = (I2F(stack[top]) < I2F(stack[top - 1]));
                    break;
                
                case 2:
                    stack[top - 1] = (I2F(stack[top]) <= I2F(stack[top - 1]));
                    break;
                
                case 3:
                    stack[top - 1] = (I2F(stack[top]) > I2F(stack[top - 1]));
                    break;
                
                case 4:
                    stack[top - 1] = (I2F(stack[top]) >= I2F(stack[top - 1]));
            }
    }
}

/* int main() {
    FILE* pcode=fopen("pcode.txt","r");
    FILE* inf=fopen("input.txt","r");
    vm_init();
    vm_load_ins(pcode);
    vm_execute(inf,stdout);
}*/