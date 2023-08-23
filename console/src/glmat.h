#ifndef __MAT_H__
#define __MAT_H__

#include <math.h>
#include <string.h>

typedef float glmat4f_t[4][4];

void glmat4f_load_identity(glmat4f_t mat){
  memset(mat, 0, sizeof(glmat4f_t));
  mat[0][0] = mat[1][1] = mat[2][2] = mat[3][3] = 1;
}

void glmat4f_mult(glmat4f_t res, glmat4f_t a, glmat4f_t b){
  glmat4f_t buffer;
  glmat4f_t *buf = (glmat4f_t*)res;
  if((res == a) || (res == b)){
    buf = (glmat4f_t*)buffer;
  }
#define RES (*(glmat4f_t*)(buf))
  RES[0][0] = a[0][0]*b[0][0] + a[0][1]*b[1][0] + a[0][2]*b[2][0] + a[0][3]*b[3][0];
  RES[0][1] = a[0][0]*b[0][1] + a[0][1]*b[1][1] + a[0][2]*b[2][1] + a[0][3]*b[3][1];
  RES[0][2] = a[0][0]*b[0][2] + a[0][1]*b[1][2] + a[0][2]*b[2][2] + a[0][3]*b[3][2];
  RES[0][3] = a[0][0]*b[0][3] + a[0][1]*b[1][3] + a[0][2]*b[2][3] + a[0][3]*b[3][3];
  
  RES[1][0] = a[1][0]*b[0][0] + a[1][1]*b[1][0] + a[1][2]*b[2][0] + a[1][3]*b[3][0];
  RES[1][1] = a[1][0]*b[0][1] + a[1][1]*b[1][1] + a[1][2]*b[2][1] + a[1][3]*b[3][1];
  RES[1][2] = a[1][0]*b[0][2] + a[1][1]*b[1][2] + a[1][2]*b[2][2] + a[1][3]*b[3][2];
  RES[1][3] = a[1][0]*b[0][3] + a[1][1]*b[1][3] + a[1][2]*b[2][3] + a[1][3]*b[3][3];
  
  RES[2][0] = a[2][0]*b[0][0] + a[2][1]*b[1][0] + a[2][2]*b[2][0] + a[2][3]*b[3][0];
  RES[2][1] = a[2][0]*b[0][1] + a[2][1]*b[1][1] + a[2][2]*b[2][1] + a[2][3]*b[3][1];
  RES[2][2] = a[2][0]*b[0][2] + a[2][1]*b[1][2] + a[2][2]*b[2][2] + a[2][3]*b[3][2];
  RES[2][3] = a[2][0]*b[0][3] + a[2][1]*b[1][3] + a[2][2]*b[2][3] + a[2][3]*b[3][3];
  
  RES[3][0] = a[3][0]*b[0][0] + a[3][1]*b[1][0] + a[3][2]*b[2][0] + a[3][3]*b[3][0];
  RES[3][1] = a[3][0]*b[0][1] + a[3][1]*b[1][1] + a[3][2]*b[2][1] + a[3][3]*b[3][1];
  RES[3][2] = a[3][0]*b[0][2] + a[3][1]*b[1][2] + a[3][2]*b[2][2] + a[3][3]*b[3][2];
  RES[3][3] = a[3][0]*b[0][3] + a[3][1]*b[1][3] + a[3][2]*b[2][3] + a[3][3]*b[3][3];
  
  if(buf == (glmat4f_t*)buffer)memcpy(res, RES, sizeof(glmat4f_t));
#undef RES
}

void mat_out(glmat4f_t mat){
  for(int j=0; j<4; j++){
    for(int i=0; i<4; i++)printf("%7.3f ", mat[i][j]);
    printf("\n");
  }
  printf("\n");
}

void glmat4f_translate(glmat4f_t res, float x, float y, float z){
  glmat4f_t mat;
  memset(mat, 0, sizeof(glmat4f_t));
  mat[0][0] = mat[1][1] = mat[2][2] = mat[3][3] = 1;
  mat[3][0] = x;
  mat[3][1] = y;
  mat[3][2] = z;
  glmat4f_mult(res, mat, res);
}

void glmat4f_scale(glmat4f_t res, float x, float y, float z){
  glmat4f_t mat;
  memset(mat, 0, sizeof(glmat4f_t));
  mat[0][0] = x;
  mat[1][1] = y;
  mat[2][2] = z;
  mat[3][3] = 1;
  glmat4f_mult(res, mat, res);
}

void glmat4f_rotatef(glmat4f_t res, float angle, float x, float y, float z){
  glmat4f_t mat;
  float s = sin(angle);
  float c = cos(angle);
  float c1 = 1.0-c;
  float len = sqrt(x*x + y*y + z*z);
  if(fabs(len) < 1e-20)return;
  x /= len; y /=len; z /= len;
  mat[0][0] = x*x*c1 + c;
  mat[1][0] = x*y*c1 - z*s;
  mat[2][0] = x*z*c1 + y*s;
  mat[3][0] = 0;
  
  mat[0][1] = y*x*c1 + z*s;
  mat[1][1] = y*y*c1 + c;
  mat[2][1] = y*z*c1 - x*s;
  mat[3][1] = 0;
  
  mat[0][2] = x*z*c1 - y*s;
  mat[1][2] = y*z*c1 + x*s;
  mat[2][2] = z*z*c1 + c;
  mat[3][2] = 0;
  
  mat[0][3] = mat[1][3] = mat[2][3] = 0;
  mat[3][3] = 1;
  
  glmat4f_mult(res, mat, res);
}

void glmat4f_frustum(glmat4f_t res, float left, float right, float bottom, float top, float Near, float Far){
  glmat4f_t mat;
  mat[0][0] = 2*Near / (left-right);
  mat[1][1] = 2*Near / (top-bottom);
  mat[2][0] = (right+left) / (right-left);
  mat[2][1] = (top+bottom) / (top-bottom);
  mat[2][2] = -(Far+Near) / (Far-Near);
  mat[3][2] = -2*(Far * Near) / (Far-Near);
  mat[1][0]=mat[3][0]=mat[0][1]=mat[3][1]=mat[0][2]=mat[1][2]=mat[0][3]=mat[1][3]=mat[3][3]=0;
  mat[2][3] = -1;
  glmat4f_mult(res, mat, res);
}

void glmat4f_ortho(glmat4f_t res, float left, float right, float bottom, float top, float Near, float Far){
  glmat4f_t mat;
  mat[0][0] = 2 / (left-right);
  mat[1][1] = 2 / (top-bottom);
  mat[2][2] = -2 / (Far-Near);
  mat[3][0] = -(right+left) / (right-left);
  mat[3][1] = -(top+bottom) / (top-bottom);
  mat[3][2] = -(Far+Near) / (Far-Near);
  mat[1][0]=mat[2][0]=mat[0][1]=mat[2][1]=mat[0][2]=mat[1][2]=mat[0][3]=mat[1][3]=mat[2][3]=0;
  mat[3][3] = 1;
  glmat4f_mult(res, mat, res);
}

void glmat4f_perspective(glmat4f_t res, float fovy, float aspect, float Near, float Far){
  float f = 1/tan(fovy/2);
  glmat4f_t mat;
  mat[0][0] = f/aspect;
  mat[1][1] = f;
  mat[2][2] = (Near+Far)/(Near-Far);
  mat[3][2] = 2*Near*Far/(Near-Far);
  mat[1][0]=mat[2][0]=mat[3][0]=mat[0][1]=mat[2][1]=mat[3][1]=mat[0][2]=mat[1][2]=mat[0][3]=mat[1][3]=mat[3][3]=0;
  mat[2][3]=-1;
  glmat4f_mult(res, mat, res);
}

void glmat4f_lookat(glmat4f_t res, float x, float y, float z, float cx, float cy, float cz, float ux, float uy, float uz){
  glmat4f_t mat;
  cx-=x; cy-=y; cz-=z;
  float len = sqrt(cx*cx + cy*cy + cz*cz);
  len = 1/len;
  cx *= len; cy *= len; cz *= len;
  float sidex, sidey, sidez;
  sidex = cy*uz - cz*uy;
  sidey = -cx*uz+ cz*ux;
  sidez = cx*uy - cy*ux;
  len = sqrt(sidex*sidex + sidey*sidey + sidez*sidez);
  len = 1/len;
  sidex *= len; sidey *= len; sidez *= len;
  
  ux = sidey*cz - sidez*cy;
  uy = -sidex*cz+ sidez*cx;
  uz = sidex*cy - sidey*cz;
  
  mat[0][0] = sidex;
  mat[1][0] = sidey;
  mat[2][0] = sidez;
  
  mat[0][1] = ux;
  mat[1][1] = uy;
  mat[2][1] = uz;
  
  mat[0][2] = -cx;
  mat[1][2] = -cy;
  mat[2][2] = -cz;
  
  mat[3][0]=mat[3][1]=mat[3][2]=mat[0][3]=mat[1][3]=mat[2][3]=0;
  mat[3][3]=1;
  glmat4f_mult(res, mat, res);
  glmat4f_translate(res, -x, -y, -z);
}

#endif