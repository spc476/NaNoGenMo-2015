/************************************************************************
*
* Copyright 2015 by Sean Conner.  All Rights Reserved.
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License
* as published by the Free Software Foundation; either version 2
* of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*
* Comments, questions and criticisms can be sent to: sean@conman.org
*
*************************************************************************/

/* http://man7.org/linux/man-pages/man2/vm86.2.html */
/* http://www.ecstaticlyrics.com/notes/vm86 */
/* http://stanislavs.org/helppc/int_21.html */
/* http://www.oldlinux.org/Linux.old/docs/interrupts/int-html/int-21.htm */
/* environment:		*/
/*	PATH=		*/
/*	COMSPEC=	*/
/*	PROMPT=		*/
/*	TMP=		*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#include <errno.h>
#include <assert.h>

#include <sys/vm86.h>
#include <sys/mman.h>
#include <cgilib6/crashreport.h>

#define SEG_ENV		0x1000
#define SEG_PSP		0x2000
#define SEG_LOAD	0x2010

#define MEM_ENV		(SEG_ENV  * 16)
#define MEM_PSP		(SEG_PSP  * 16)
#define MEM_LOAD	(SEG_LOAD * 16)

/********************************************************************/

typedef struct fcbs	/* short FCB block */
{
  char     drive;
  char     name[8];
  char     ext[3];
  uint16_t cblock;
  uint16_t recsize;
} __attribute__((packed)) fcbs__s;

typedef struct fcb
{
  char     drive;
  char     name[8];
  char     ext[3];
  uint16_t cblock;
  uint16_t recsize;
  uint32_t size;
  uint16_t date;
  uint16_t time;
  uint16_t rsvp0;
  uint8_t  crecnum;
  uint32_t relrec;
} fcb__s;

typedef struct psp
{
  uint8_t  warmboot[2];		/* 0xCD, 0x20 */
  uint16_t last_seg;
  uint8_t  rsvp0;
  uint8_t  oldmscall_jmp;	/* 0x9A, offlo, offhi, seglo, seghi */
  uint16_t oldmscall_off;
  uint16_t oldmscall_seg;
  uint16_t termaddr[2];
  uint16_t ctrlcaddr[2];
  uint16_t erroraddr[2];
  uint8_t  rsvp1[22];
  uint16_t envp;
  uint8_t  rsvp2[34];
  uint8_t  mscall[3];		/* 0xCD , 0x21 , 0xCB */
  uint8_t  rsvp3[9];
  fcbs__s  primary;
  fcbs__s  secondary;
  uint8_t  rsvp[4];
  uint8_t  cmdlen;
  uint8_t  cmd[127];
} __attribute__((packed)) psp__s;

typedef struct exehdr
{
  uint8_t  magic[2];	/* 0x4D, 0x5A */
  uint16_t lastpagesize;
  uint16_t filepages;
  uint16_t numreloc;
  uint16_t hdrpara;
  uint16_t minalloc;
  uint16_t maxalloc;
  uint16_t init_ss;
  uint16_t init_sp;
  uint16_t chksum;
  uint16_t init_ip;
  uint16_t init_cs;
  uint16_t reltable;
  uint16_t overlay;
} __attribute__((packed)) exehdr__s;

typedef struct system
{
  struct vm86plus_struct  vm;
  unsigned char          *mem;
  size_t                  fcbidx[16];
  fcb__s                  fcbs[16];
  FILE                   *fp[16];
  size_t                  fcb_max;
  uint16_t                dtaseg;
  uint16_t                dtaoff;
} system__s;

/********************************************************************/

static void dump_memory(unsigned char *mem,size_t size)
{
  FILE *fp = fopen("msdos.core","wb");
  if (fp != NULL)
  {
    fwrite(mem,1,size,fp);
    fclose(fp);
  }
}

/********************************************************************/

static void dump_regs(struct vm86_regs *regs)
{
  char flags[17];
  
  flags[ 0] = '-';
  flags[ 1] = '-';
  flags[ 2] = '-';
  flags[ 3] = '-';
  flags[ 4] = regs->eflags & 0x0800 ? 'O' : 'o';
  flags[ 5] = regs->eflags & 0x0400 ? 'D' : 'd';
  flags[ 6] = regs->eflags & 0x0200 ? 'I' : 'i';
  flags[ 7] = regs->eflags & 0x0100 ? 'T' : 't';
  flags[ 8] = regs->eflags & 0x0080 ? 'S' : 's';
  flags[ 9] = regs->eflags & 0x0040 ? 'Z' : 'z';
  flags[10] = '-';
  flags[11] = regs->eflags & 0x0010 ? 'A' : 'a';
  flags[12] = '-';
  flags[13] = regs->eflags & 0x0004 ? 'P' : 'p';
  flags[14] = '-';
  flags[15] = regs->eflags & 0x0001 ? 'C' : 'c';
  flags[16] = '\0';
  
  fprintf(
          stderr,
          "AX: %04lX BX: %04lX CX: %04lX DX: %04lX\n"
          "SI: %04lX DI: %04lX BP: %04lX SP: %04lX\n"
          "IP: %04lX FL: %s\n"
          "CS: %04X DS: %04X ES: %04X SS: %04X\n"
          "\n",
          regs->eax & 0xFFFF,
          regs->ebx & 0xFFFF,
          regs->ecx & 0xFFFF,
          regs->edx & 0xFFFF,
          regs->esi & 0xFFFF,
          regs->edi & 0xFFFF,
          regs->ebp & 0xFFFF,
          regs->esp & 0xFFFF,
          regs->eip & 0xFFFF,
          flags,
          regs->cs,
          regs->ds,
          regs->es,
          regs->ss
  );
}

/********************************************************************/

static int load_exe(
        const char       *fname,
        unsigned char    *mem,
        struct vm86_regs *regs
)
{
  exehdr__s  hdr;
  size_t     binsize;
  size_t     i;
  uint16_t   off[2];
  FILE      *fp;
  psp__s    *psp;
  uint16_t  *patch;
  size_t     offset;
  
  assert(fname != NULL);
  assert(regs  != NULL);
  
  memset(&mem[MEM_ENV],0,256);
  psp = (psp__s *)&mem[MEM_PSP];
  
  memset(psp,0,256);
  psp->warmboot[0]   = 0xCD;
  psp->warmboot[1]   = 0x20;
  psp->oldmscall_jmp = 0x9A;
  psp->oldmscall_off = 0;
  psp->oldmscall_seg = SEG_PSP;
  psp->termaddr[0]   = 0;
  psp->termaddr[1]   = SEG_PSP;
  psp->ctrlcaddr[0]  = 0;
  psp->ctrlcaddr[1]  = SEG_PSP;
  psp->erroraddr[0]  = 0;
  psp->erroraddr[1]  = SEG_PSP;
  psp->envp          = SEG_ENV;
  psp->mscall[0]     = 0xCD;
  psp->mscall[1]     = 0x21;
  psp->mscall[2]     = 0xCB;
  psp->cmdlen        = 0;
  
  fp = fopen(fname,"rb");
  if (fp == NULL)
  {
    perror(fname);
    return errno;
  }
  
  fread(&hdr,sizeof(hdr),1,fp);
#if 0
  fprintf(
    stderr,
    "lastpage:  %d\n"
    "filepages: %d (%u)\n"
    "numreloc:  %d\n"
    "hdrpara:   %d\n"
    "minalloc:  %d\n"
    "maxalloc:  %d\n"
    "SS:SP:     %04X:%04X\n"
    "CS:IP:     %04X:%04X\n"
    "reltable:  %04X\n"
    "overlay:   %d\n"
    "\n",
    hdr.lastpagesize,
    hdr.filepages , hdr.filepages * 512 + hdr.lastpagesize,
    hdr.numreloc,
    hdr.hdrpara,
    hdr.minalloc,
    hdr.maxalloc,
    hdr.init_ss,hdr.init_sp,
    hdr.init_cs,hdr.init_ip,
    hdr.reltable,
    hdr.overlay
  );
#endif
  regs->cs  = hdr.init_cs + SEG_LOAD;
  regs->eip = hdr.init_ip;
  regs->ss  = hdr.init_ss + SEG_LOAD;
  regs->esp = hdr.init_sp;
  regs->ds  = SEG_PSP;
  regs->es  = SEG_PSP;
  regs->eax = 0xFFFF;
  binsize   = (hdr.filepages * 512 + hdr.lastpagesize) - (hdr.hdrpara * 16);
  
  fseek(fp,hdr.hdrpara * 16,SEEK_SET);
  fread(&mem[MEM_LOAD],1,binsize,fp);
  fseek(fp,hdr.reltable,SEEK_SET);
  
  for (i = 0 ; i < hdr.numreloc ; i++)
  {
    fread(&off,sizeof(off),1,fp);
    offset  = off[1] * 16 + off[0];
    patch   = (uint16_t *)&mem[MEM_LOAD + offset];
    *patch += (uint16_t)SEG_LOAD;    
  }
  
  fclose(fp);
  return 0;  
}

/********************************************************************/

static void ms_dos(system__s *sys)
{
  int ah;
  int dl;
  size_t idx;
  fcb__s *fcb;
  char drive;
 
  assert(sys != NULL); 
  
  ah = (sys->vm.regs.eax >> 8) & 255;
  switch(ah)
  {
    case 0:	/* exit */
         exit(0);
    
    case 0x06: /* direct console I/O */
         dl = sys->vm.regs.edx & 255;
         if (dl < 255)
         {
           putchar(dl);
           sys->vm.regs.eax &= 0xFF;
           sys->vm.regs.eax |= dl;
         }
         else
         {
           sys->vm.regs.eflags |= 0x40;
           sys->vm.regs.eax &= 0xFF;
         }
         break;
    
    case 0x0F: /* Open file (1.0 version) */
         idx   = sys->vm.regs.ds * 16 + (sys->vm.regs.edx & 0xFFFF);
         assert(idx < 1024*1024uL);
         fcb   = (fcb__s *)&sys->mem[idx];
         drive = '@' + fcb->drive;
         fprintf(stderr,"%c %.8s %.3s\n",drive,fcb->name,fcb->ext);
         dump_regs(&sys->vm.regs);
         dump_memory(sys->mem,1024*1024);
         exit(1);
         
    case 0x1A: /* set DTA address (sigh) */
         sys->dtaseg = sys->vm.regs.ds;
         sys->dtaoff = sys->vm.regs.edx & 0xFFFF;
         break;
         
    default:
         fprintf(stderr,"\n\nUnimplented function %02X\n",ah);
         dump_regs(&sys->vm.regs);
         exit(1);
  }  
}

/********************************************************************/

static system__s g_sys = { .mem = MAP_FAILED };

static void cleanup(void)
{
  if (g_sys.mem != MAP_FAILED)
    munmap(g_sys.mem,1024*1024);
}

int main(int argc,char *argv[])
{
  if (argc < 2)
  {
    fprintf(stderr,"usage: %s file\n",argv[0]);
    return EXIT_FAILURE;
  }
  
  atexit(cleanup);
  crashreport(SIGSEGV);
  
  g_sys.mem = mmap(0,1024*1024,PROT_EXEC | PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS|MAP_FIXED,-1,0);
  if (g_sys.mem == MAP_FAILED)
  {
    perror("mmap()");
    return EXIT_FAILURE;
  }
  
  memset(g_sys.mem,0xCC,1024*1024);  
  memset(&g_sys.vm,0,sizeof(g_sys.vm));
  memset(&g_sys.vm.int_revectored,  255,sizeof(g_sys.vm.int_revectored));
  memset(&g_sys.vm.int21_revectored,255,sizeof(g_sys.vm.int21_revectored));
  g_sys.vm.cpu_type = CPU_086;
  
  load_exe(argv[1],g_sys.mem,&g_sys.vm.regs);
  
  while(true)
  {
    int rc   = vm86(VM86_ENTER,&g_sys.vm);
    int type = VM86_TYPE(rc);
    int arg  = VM86_ARG(rc);
    
    if (rc < 0)
    {
      perror("vm86()");
      return EXIT_FAILURE;
    }
    
    if (type != VM86_INTx)
    {
      fprintf(stderr,"ERROR: type=%d arg=%d\n",type,arg);
      return EXIT_FAILURE;
    }
    
    if (arg == 0x20) break;
    if (arg != 0x21)
    {
      fprintf(stderr,"unexpected interrupt %02X\n",arg);
      return EXIT_FAILURE;
    }
    
    ms_dos(&g_sys);
  }
  
  dump_memory(g_sys.mem,1024*1024);
  return EXIT_SUCCESS;
}

/********************************************************************/
