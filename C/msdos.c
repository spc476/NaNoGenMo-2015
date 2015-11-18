
/* http://man7.org/linux/man-pages/man2/vm86.2.html */
/* http://www.ecstaticlyrics.com/notes/vm86 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <sys/vm86.h>
#include <sys/mman.h>
#include <cgilib6/crashreport.h>

int main(void)
{
  struct vm86plus_struct  vm;
  unsigned char          *mem;
  int                     rc;
  
  crashreport(SIGSEGV);
  
  mem = mmap(0,1024*1024,PROT_EXEC | PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS|MAP_FIXED,-1,0);
  if (mem == MAP_FAILED)
  {
    perror("mmap()");
    return EXIT_FAILURE;
  }
  
  memset(&vm,0,sizeof(vm));
  memset(&vm.int_revectored,  255,sizeof(vm.int_revectored));
  memset(&vm.int21_revectored,255,sizeof(vm.int21_revectored));
  
  vm.cpu_type = CPU_086;
  vm.regs.cs  = 0x100;
  vm.regs.eip = 0x10;
  vm.regs.ss  = 0x200;
  vm.regs.esp = 0xFFFE;
  
  mem[0x1010] = 0xB8;
  mem[0x1011] = 0x34;
  mem[0x1012] = 0x12;  
  mem[0x1013] = 0xCD;
  mem[0x1014] = 0x21;
  mem[0x1015] = 0xCD;
  mem[0x1016] = 0x20;
  
  rc = vm86(VM86_ENTER,&vm);
  if (rc < 0)
    perror("vm86()");
  else
  {
    printf("%d:%d\n",VM86_TYPE(rc),VM86_ARG(rc));
    printf("%08lX %08lX %08lX\n",vm.regs.eip,vm.regs.eax,vm.regs.orig_eax);
    printf("%02X\n",mem[0x1010]);
  }
  
  munmap(mem,1024*1024);
  return EXIT_SUCCESS;
}
