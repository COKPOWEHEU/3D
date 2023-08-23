#include <stdio.h>
#include <signal.h>
#include <string.h>
#include <math.h>
#include <unistd.h>
 
#define SCR_W 40
#define SCR_H 20
 
char screen[SCR_H][SCR_W];
double zbuf[SCR_H][SCR_W];
 
void swap_buffers(){
  printf("\033[1H");
  for(int i=0; i<SCR_H; i++){
    fwrite(screen[i], 1, SCR_W, stdout);
    putchar('\n');
  }
}
void pixel(int x, int y, char ch){
  if( (x<0)||(x>SCR_W) )return;
  if( (y<0)||(y>SCR_H) )return;
  screen[y][x] = ch;
}
void clear(){
  memset(screen, ' ', sizeof(screen));
  memset(zbuf, 0, sizeof(zbuf));
}
 
typedef struct{
  double x,y,z;
  char col;
}vector_t;
 
typedef double matrix_t[4][4];
 
void line(vector_t v1, vector_t v2){
  int x1 = v1.x, x2 = v2.x;
  int y1 = v1.y, y2 = v2.y;
  int dx = x2 - x1;
  if(dx < 0){
    dx=y1; y1=y2; y2=dx;
    dx=x1; x1=x2; x2=dx; dx=x2-x1;
  }
  int dy = y2 - y1;
  int ddy = 1;
  if(dy < 0){
    ddy = -1;
    dy = -dy;
  }
  if( (dx == 0) && (dy == 0) )return;
  int err = 0;
  for(;x1<=x2;x1++){
    err += dy;
    do{
      pixel(x1, y1, v1.col);
      if(err < dx)break;
      err -= dx;
      y1 += ddy;
      if(y1 == y2)return;
    }while(err >= dx);
  }
}
 
void mat_iden(matrix_t mat){
  memset(mat, 0, sizeof(matrix_t));
  mat[0][0]=1; mat[1][1]=1; mat[2][2]=1;
}
void mat_mul(matrix_t m1, matrix_t m2, matrix_t res){
  matrix_t t;
  memset(t, 0, sizeof(matrix_t));
  for(int i=0; i<4; i++)
    for(int j=0; j<4; j++)
      for(int k=0; k<4; k++)
        t[i][j] += m1[i][k] * m2[k][j];
  memcpy(res, t, sizeof(matrix_t));
}
void mat_rotX(double alp, matrix_t mat){
  mat[0][0]=1; mat[1][0]=0;        mat[2][0]=0;        mat[3][0]=0;
  mat[0][1]=0; mat[1][1]=cos(alp); mat[2][1]=-sin(alp);mat[3][1]=0;
  mat[0][2]=0; mat[1][2]=sin(alp); mat[2][2]=cos(alp); mat[3][2]=0;
  mat[0][3]=0; mat[1][3]=0;        mat[2][3]=0;        mat[3][3]=1;
}
void mat_rotY(double alp, matrix_t mat){
  mat[0][0]=cos(alp); mat[1][0]=0; mat[2][0]=-sin(alp);mat[3][0]=0;
  mat[0][1]=0;        mat[1][1]=1; mat[2][1]=0;        mat[3][1]=0;
  mat[0][2]=sin(alp); mat[1][2]=0; mat[2][2]=cos(alp); mat[3][2]=0;
  mat[0][3]=0;        mat[1][3]=0; mat[2][3]=0;        mat[3][3]=1;
}
void mat_rotZ(double alp, matrix_t mat){
  mat[0][0]=cos(alp); mat[1][0]=-sin(alp);mat[2][0]=0; mat[3][0]=0;
  mat[0][1]=sin(alp); mat[1][1]=cos(alp); mat[2][1]=0; mat[3][1]=0;
  mat[0][2]=0;        mat[1][2]=0;        mat[2][2]=1; mat[3][2]=0;
  mat[0][3]=0;        mat[1][3]=0;        mat[2][3]=0; mat[3][3]=1;
}
void mat_trans(double x, double y, double z, matrix_t mat){
  memset(mat, 0, sizeof(matrix_t));
  mat[0][0]=1; mat[1][1]=1; mat[2][2]=1; mat[3][3]=1;
  mat[3][0]=x; mat[3][1]=y; mat[3][2]=z;
}
void vecmat(vector_t src, matrix_t mat, vector_t *res){
  res->x = src.x*mat[0][0] + src.y*mat[1][0] + src.z*mat[2][0] + mat[3][0];
  res->y = src.x*mat[0][1] + src.y*mat[1][1] + src.z*mat[2][1] + mat[3][1];
  res->z = src.x*mat[0][2] + src.y*mat[1][2] + src.z*mat[2][2] + mat[3][2];
  res->col = src.col;
}
void avecmat(vector_t src[], matrix_t mat, vector_t res[], int N){
  for(int i=0; i<N; i++)vecmat(src[i], mat, &(res[i]));
}
 
volatile char runflag = 1;
void sig(int num){
  runflag = 0;
}
int main(){
  signal(SIGINT, sig);
  float alp = 0;
  int x = SCR_W/2, y=SCR_H/2, r=SCR_H*0.6;
  vector_t src[4] = {
    {.x=0, .y=0, .z=0, .col='1'},
    {.x=r, .y=0, .z=0, .col='2'},
    {.x=0, .y=r, .z=0, .col='3'},
    {.x=0, .y=0, .z=r, .col='4'},
  };
  vector_t res[4];
  matrix_t mat, temp;
  while(runflag){
    clear();
    mat_rotZ(alp, mat);
    mat_rotX(alp*1.1, temp);
    mat_mul(mat, temp, mat);
    mat_trans(x,y,0, temp);
    mat_mul(mat, temp, mat);
    avecmat(src, mat, res, 4);
 
    line(res[0], res[1]);
    line(res[0], res[2]);
    line(res[0], res[3]);
    line(res[1], res[2]);
    line(res[2], res[3]);
    line(res[3], res[1]);
    
    alp += 0.001;
    usleep(1000);
    swap_buffers();
  }
}