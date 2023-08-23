#ifndef __CONSOLE_H__
#define __CONSOLE_H__

#if defined(linux) || defined(__linux) || defined(__linux__) || defined(__GNU__) || defined(__GLIBC__)

#include <termios.h>
#include <sys/ioctl.h>

//инициализация (если хочется заблокировать сигналы, добавить ISIG)
void term_nocanon(char flag_en){
  static struct termios savetty;
  static char saved = 0;
  struct termios tty;
  if( !saved ){
    tcgetattr (0, &tty);
    savetty = tty;
    flag_en = 1;
    saved = 1;
  }
  if(flag_en){
    tcgetattr (0, &tty);
    tty.c_lflag &= ~(ICANON | ECHO);
    tty.c_cc[VTIME] = 0;
    tty.c_cc[VMIN] = 0;
    tcsetattr (0, TCSAFLUSH, &tty);
    printf("\e[?25l");
  }else{
    tcsetattr (0, TCSANOW, &savetty);
    printf("\e[?25h");
  }
}

#define con_noncanon() term_nocanon(1)
#define con_canon() term_nocanon(0);

int con_getch(){
  char ch = 0;
  if(read(0, &ch, 1) == 1)return ch;
  return -1;
}
void con_goto(int x, int y){
  printf("\033[%i;%iH", y, x);
}
void con_clear(){
  printf("\033[2J\033[1;1H");
}
void con_getsize(int *w, int *h){
  struct winsize ws;
  ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws);
  *w = ws.ws_col;
  *h = ws.ws_row;
}
void con_write(char *buf, size_t size){
  fwrite(buf, size, 1, stdout);
}
#elif defined(_WIN32) || defined(__WIN32__) || defined(WIN32)
#define _CRT_SECURE_NO_WARNINGS //что-то нужное для совместимости с MS Visual Studio
#define _USE_MATH_DEFINES
#include <windows.h>
#include <conio.h>
void con_noncanon(){
  HANDLE consoleHandle = GetStdHandle(STD_OUTPUT_HANDLE);
  CONSOLE_CURSOR_INFO info;
  info.dwSize = 100;
  info.bVisible = FALSE;
  SetConsoleCursorInfo(consoleHandle, &info);
}
void con_canon(){
  HANDLE consoleHandle = GetStdHandle(STD_OUTPUT_HANDLE);
  CONSOLE_CURSOR_INFO info;
  info.dwSize = 100;
  info.bVisible = TRUE;
  SetConsoleCursorInfo(consoleHandle, &info);
}
int con_getch(){if(kbhit())return getc(stdin); else return -1;}
void con_goto(int x, int y){
  COORD Coord = {.X=x, .Y=y};
  SetConsoleCursorPosition(GetStdHandle(STD_OUTPUT_HANDLE), Coord);
}
void con_clear(){system("cls");}
void con_getsize(int *w, int *h){
  CONSOLE_SCREEN_BUFFER_INFO csbi;
  GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &csbi);
  *w = csbi.srWindow.Right - csbi.srWindow.Left;
  *h = csbi.srWindow.Bottom - csbi.srWindow.Top;
}
void con_write(char *buf, size_t size){
  HANDLE hOutput = (HANDLE)GetStdHandle(STD_OUTPUT_HANDLE);
  DWORD nWritten;
  WriteConsole(hOutput, buf, size, &nWritten, NULL);
}

#else
#error system not supported
void con_noncanon(){}
void con_canon(){}
int con_getch(){return 27;}
void con_goto(int x, int y){}
void con_clear(){}
void con_getsize(int *w, int *h){}
void con_write(char *buf, size_t size){}
#endif

#endif