// zoo.h

#include <stdio.h>
#include <cbm.h>
#include <string.h>
#include <time.h>
#include <conio.h>
#include <stdlib.h>
#include <ctype.h>

#define EMPTY_SYMB 0xff
#define JOKER_SYMB 0xb0

#define SWAP_DELAY 100
#define XOFFS 2
#define TIME_BONUS 2

#define fire_up 110
#define fire_down 109
#define fire_left 107
#define fire_right 103
#define fire 111
#define nothing 127

// globals

extern char cue[16];
extern char cue_max,demo;

extern struct hs{
	char name[11];
	char level;
	unsigned long score;
} highscore[10];

struct {
	char x; 
	char y;
	unsigned num; 
} scores[64];

char del,chk_flg,no_more_moves_flag;
unsigned long score[2];
unsigned long s_temp;	//#
unsigned int sc;
clock_t jok1;
char str_dummy[21];
char backup[8][8];
char hits[8];

struct __vic2 *vic = (void*)0xd000;
unsigned char *spr_ptr = (void*)0x7f8;

// constant values

const char x_offsets[]={3,4,6};
const char y_offsets[]={4,6,7};
const char sc_coltab[] = {6,3,1};
const char hs_coltab1[] = { 3,14, 6, 4,10, 8, 8, 7,13, 5};
const char hs_coltab2[] = {15,15,14, 8, 2,10, 7,15,15,13};
const char hs_coltab3[] = {0,11,11,12,12,15,15,1};
static const char level_time[] = {12,10, 9, 8, 7, 6, 5, 4, 3, 3, 3, 2, 2, 2, 1, 1};
static const char time_bonus[] = { 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 4, 4, 4, 6, 6};

char mssg[16][16] = 	{	
				"panda party",
				"monkey business",
				"lion's den",
				"happy hippo",
				"elephant walk",
				"bullride",
				"tough giraffe",
				"safari",
				"animal farm",
				"ape escape",
				"crocodile rock",
				"rhino dance",
				"rock'n'roll",
				"rodeo",
				"zoo maniac",
				"quick'n'dirty"
};

// extern variables & function prototypes from assembler file "zoo_ass.s"

extern char bmp_data;
extern unsigned char is_title,animals,joystick_delay,key,keyboard,up,down,left,right,matrix[8][8],colortab[8];
extern unsigned char timer_delay,time_out,stop,joker,joker_tmp,players;
extern unsigned char joker_x,joker_y;
extern unsigned int time1;
extern signed char xdir1,ydir1,xdir2,ydir2,xpos1,ypos1,xpos2,ypos2;
extern unsigned char level,pm_x1,pm_x2,pm_y1,pm_y2,pl,fld_done;
extern unsigned char team,tt;

void title_irq(void);
void game_irq(void);
void inter_irq(void);
void __fastcall__ init_msx(unsigned char tune);
void __fastcall__ setgfx(int);
void __fastcall__ wait(char);
unsigned char random(void);
unsigned char __fastcall__ pet2scr(unsigned char);
unsigned char isstop(void);
void wait_for_key_or_joy(void);
unsigned char _check_matrix(void);
void __fastcall__ print2x2_centered(char *str,char color1, char color2,char line);
void __fastcall__ plot2x2_xy (char c,char x,char y,char color1,char color2);
void ass_setup(void);
void cursor_on(void);
void cursor_off(void);

// local prototypes from "zoo.c"
void gfx_setup(void);
void gfx_mode(void);
void txt_mode(void);
void __fastcall__ setxy(char x,char y);
void __fastcall__ plot_score(unsigned s,char x,char y);
void __fastcall__ print_num(unsigned long sc,char n,char x,char y);
void __fastcall__ print3x3(char symb,char x, char y);
void print_hits(void);
void print_matrix(void);
void broesel(void);
void no_more_moves(void);
void show_highscores(void);
void title_screen(void);
void level_up_screen(void);
void time_out_screen(void);
void pause_screen(void);
void display_time(void);
void kill_joker(void);
unsigned char __fastcall__ check_moves(void);
void move_matrix(void);
void __fastcall__ check_matrix(unsigned char fo);
unsigned char get_random_symb(void);
void fill_matrix(void);
void __fastcall__ clone(char i, char j,char s);
void __fastcall__ swap(char x, char y,char xswap,char yswap);
unsigned char yesno(void);
void fill(void);
void load_hs(void);
void save_hs(void);
void appear(void);
unsigned char getkey(void);
void __fastcall__ print2spr(char*,char);
extern unsigned char getfromcue(void);
extern void __fastcall__ put2cue(char);
extern void __fastcall__ do_bar(char);
void __fastcall__ delay(char);
void __fastcall__ fld(char);
void screen_on(void);
void screen_off(void);
void __fastcall__ joker_hit(char pl);
