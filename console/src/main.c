#include <stdio.h>
#include <signal.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "console.h"
#include "glmat.h"
typedef struct{
  float x,y,z;
}vertex3;
vertex3 *vec, *norm;
void draw_triangle(vertex3 *a, vertex3 *b, vertex3 *c, vertex3 *norm);
#include "fly.h"
#define vec_src fly_vec
#define norm_src fly_norm
#define draw_model Draw_fly
#define vec_size (sizeof(vec_src)/sizeof(vec_src[0]))
#define norm_size (sizeof(norm_src)/sizeof(norm_src[0]))

#define MODE_THETRA	0
#define MODE_FLY	1

vertex3 tetra[] = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}, {0, 0, 0}};
const char color[32] = " `',\";;i!lt(7I14YkVA$O9E&DRB@HHM";
char *buf = NULL;
float *zbuf = NULL;
int SCR_W=0, SCR_H=0;
int SCR_W2=0, SCR_H2;
#define PIX(x,y) (buf[x + y*SCR_W])
#define ZBUF(x,y) (zbuf[x + y*SCR_W])
glmat4f_t mat;

void glmat4f_apply(vertex3 *dst, vertex3 *src, glmat4f_t mat, size_t vertex_count){
  for(size_t i=0; i<vertex_count; i++){
    dst[i].x = SCR_W2 + SCR_W2*(src[i].x*mat[0][0] + src[i].y*mat[1][0] + src[i].z*mat[2][0] + mat[3][0]);
    dst[i].y = SCR_H2 + SCR_H2*(src[i].x*mat[0][1] + src[i].y*mat[1][1] + src[i].z*mat[2][1] + mat[3][1]);
    dst[i].z = src[i].x*mat[0][2] + src[i].y*mat[1][2] + src[i].z*mat[2][2] + mat[3][2];
  }
}

void swap_buffers(){
  con_goto(1,1);
  for(int j=0; j<SCR_H; j++){
    con_write(&(buf[j*SCR_W]), SCR_W);
    con_write("\n", 1);
  }
  memset(buf, ' ', SCR_W*SCR_H);
  memset(zbuf, 0, SCR_W*SCR_H*sizeof(zbuf[0]));
}
void putpix(int x, int y, float z, float col){
  if((x<0)||(x>=SCR_W)||(y<0)||(y>=SCR_H))return;
  int k = x + y*SCR_W;
  if(zbuf[k] > z)return;
  zbuf[k] = z;
  if(col < 0)col = 0;
  if(col > 1)col = 1;
  buf[k] = color[(int)((sizeof(color)-1)*col+0.5)];
}

void line_horiz(int x1, int x2, int y, float z1, float z2, float col){
  if(x1 == x2){
    if(z1 > z2)z1=z2;
    putpix(x1, y, z1, col);
    return;
  }
  float dz = (z2-z1)/(x2-x1);
  if(x2 < x1){int x=x1; x1=x2; x2=x; z1=z2;}
  int dx = x2-x1;
  for(int i=0; i<=dx; i++){
    putpix(x1+i, y, z1+dz*i, col);
  }
}
void triangle(vertex3 *a, vertex3 *b, vertex3 *c, float col){
  vertex3 *temp;
  if(a->y > b->y){temp=a; a=b; b=temp;}
  if(a->y > c->y){temp=a; a=c; c=temp;}
  if(b->y > c->y){temp=b; b=c; c=temp;}
  
  float dy1 = (b->y - a->y);
  float dy2 = (c->y - a->y);
  float dx1 = (b->x - a->x)/dy1;
  float dx2 = (c->x - a->x)/dy2;
  float z1 = a->z;
  float dz1 = (b->z - a->z)/dy1;
  float dz2 = (c->z - a->z)/dy2;
  int x1 = a->x;
  int y = a->y;
  for(int i=0; i<dy1; i++){
    line_horiz(x1+dx1*i, x1+dx2*i, y+i, z1+dz1*i, z1+dz2*i, col);
  }
  int x2 = x1 + dx2*dy1;
  x1 = b->x;
  float z2 = z1 + dz2*dy1;
  z1 = b->z;
  dy1 = (c->y - b->y);
  dx1 = (c->x - b->x)/dy1;
  dz1 = (c->z - b->z)/dy1;
  y = b->y;
  for(int i=0; i<=dy1; i++){
    line_horiz(x1+dx1*i, x2+dx2*i, y+i, z1+dz1*i, z2+dz2*i, col);
  }
}
void draw_triangle(vertex3 *a, vertex3 *b, vertex3 *c, vertex3 *norm){
  vertex3 light = {0.5, 0.5, 0.5};
  float len = (norm->x*norm->x + norm->y*norm->y + norm->z*norm->z);
  len = 1/sqrt(len);
  float col = light.x*norm->x + light.y*norm->y + light.z*norm->z;
  col *= len;
  triangle(a, b, c, col);
}

volatile char runflag = 1;
void sig(int num){
  runflag = 0;
}
int main(int argc, char **argv){
  char mode = MODE_FLY;
  if(argc > 1){
    if(strcmp(argv[1], "-h")==0){
      printf("Usage: %s [flags]\n", argv[0]);
      printf("\t--tetra   : draw tetrahedron\n");
      printf("\t--fly     : draw fly\n");
      return 0;
    }else if(strcmp(argv[1], "--tetra")==0){
      mode = MODE_THETRA;
    }else if(strcmp(argv[1], "--fly")==0){
      mode = MODE_FLY;
    }
  }
  signal(SIGINT, sig);
  con_noncanon();
  con_clear();
  con_getsize(&SCR_W, &SCR_H);
  SCR_W--; SCR_H--;
  SCR_W2=SCR_W/2; SCR_H2=SCR_H/2;
  buf = malloc(sizeof(char)*SCR_W*SCR_H);
  memset(buf, ' ', SCR_W*SCR_H);
  zbuf = malloc(sizeof(float)*SCR_W*SCR_H);
  vec = malloc(sizeof(vertex3)*vec_size);
  norm = malloc(sizeof(vertex3)*norm_size);
  con_noncanon();
  con_clear();
  float alp = 0;
  float alp2= 0;
  glmat4f_t transf, scrmat;
  
  glmat4f_load_identity(scrmat);
  glmat4f_ortho(scrmat, -1, 1, -1, 1, 0.1, 10);
  glmat4f_lookat(scrmat, 0,0,10, 0,0,0, 0,1,0);
  
  while(runflag && (con_getch() <= 0)){
    glmat4f_load_identity(transf);
    glmat4f_rotatef(transf, alp, 1, 1, 1);
    glmat4f_rotatef(transf, alp2, 1, 0, 0);
    
    if(mode == MODE_FLY){
      glmat4f_apply(norm, (vertex3*)norm_src, transf, norm_size);
      glmat4f_mult(transf, transf, scrmat);
      glmat4f_apply(vec, (vertex3*)vec_src, transf, vec_size);
      
      draw_model();
    }else{
      glmat4f_mult(transf, transf, scrmat);
      glmat4f_apply(vec, tetra, transf, 4);
      
      triangle(&vec[0], &vec[1], &vec[2], 0.25);
      triangle(&vec[3], &vec[0], &vec[1], 0.5);
      triangle(&vec[3], &vec[1], &vec[2], 0.75);
      triangle(&vec[3], &vec[0], &vec[2], 0.1);
    }

    alp += 0.05;
    alp2 += 0.03;
    usleep(50000);
    swap_buffers();
  }
  
  con_canon();
  con_clear();
  free(vec);
  free(norm);
  free(buf);
  free(zbuf);
  return 0;
}