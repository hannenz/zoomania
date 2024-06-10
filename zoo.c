/**
 * zoo.c
 *
 * @author Johannes Braun <johannes.braun@swu.de>
 * @package zoo
 * @version 2024-06-09
 *
 * TO DO:
 * 
 * - missing tune
 * - zeigt letzten zug falsch an!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 * - kernal mssg bei load abschalten!
 */
#include "zoo.h"
#define LINES 17

//print a 2x2 number to x/y with n digits
void __fastcall__ print_num(unsigned long sc,char n,char x,char y){
	char i = n;
	char c1 = 3;
	char c2 = 6;
	
	if (n == 2){
		c1 = 1;
		c2 = 2;
	}
	
	else if (players == 1 && y == 22){
		c1 = 1;
		c2 = 2;
	}
	
	for (i=0;i<n;++i){
		str_dummy[n-i-1] = sc%10 + 36;	//calculate digits
		sc/=10;
	}
	
	for (i=0;i<n;++i){
		plot2x2_xy(str_dummy[i],x,y,c1,c2); //and plot them
		x += 2;
	}
}


void print_hits(void){
	unsigned char i,j,col,*screen;
	unsigned char n = 0;

	for (i=0;i<animals;++i){
		if (hits[i]){
			col = colortab[i]|8;
			plot2x2_xy(51+i,35,n,col,col);
			plot_score(hits[i],37,n);
			n+=2;
		}
	}

	screen = (char*)0x423 + 40*n;

	for (i=n;i<16;++i){
		for (j=0;j<5;++j){
			*screen++ = EMPTY_SYMB;
		}
		screen += 35;
	}
}

//print the matrix
void print_matrix(void){
	char p,l;
	
	fill();
	cursor_off();
	print_hits();

	l = 20-(players<<1);
	print_num(level,2,36,l);
	for (p=0;p<players+1;++p){
		l += 2;
		print_num(score[p],6,28,l);
	}
	stop = 1;	
	display_time();
	appear();
	cursor_on();
	delay(230);
}

void no_more_moves(void){
	broesel();
	txt_mode();
	print2x2_centered("no more moves",13,5,8);
	fill_matrix();
}

void show_highscores(void){
	char i,j;
	
	screen_off();
	init_msx(0);
	fill();
	txt_mode();

	print2x2_centered("highscores",1,15,0);
	for (i=0;i<10;++i){
		sprintf(str_dummy,"%-10s %06lu-%02d",highscore[i].name,highscore[i].score,highscore[i].level);
		print2x2_centered(str_dummy,hs_coltab1[i],hs_coltab2[i],3+(i<<1));
	}
	revers(1);textcolor(15);
	cputsxy(9,24,"[s] to save highscores");
	screen_on();

	while(*(char*)0xdc00 == 127){
		wait(0x33+24*8-2);
		setgfx(0x0428);
		wait(0);
		setgfx(0x0438);
		
		++j;
		if ((j & 3) == 0){
			++i;
			memset((char*)0xdbc9,hs_coltab3[i&7],22);
		}

		if (getkey() == 's'){
			screen_off();
			save_hs();
			screen_on();
		}
	}
	screen_off();
	fill();
	delay(35);
	screen_on();
}

void title_screen(void){
	char j,k,choice;

	while(1){
		stop = 1;
		players = team = demo = choice = tt = 0;
		init_msx(2);
		title_irq();
		cursor_off();

		// Set Color RAM from data
		memmove((char*)0xd800,(char*)(&bmp_data + LINES*40 + LINES*320),LINES*40);

//		memset((char*)0xcea8,0xff,40);
		fill();
		revers(1);
		textcolor(1); cputsxy(12,18,	"one player game");
		textcolor(2); cputsxy(12,19,	"two player team");
		textcolor(7); cputsxy(11,20,	"two player battle");
		textcolor(2); cputsxy(15,21,	"highscores");
//		textcolor(1); cputsxy(18,22,	"demo");

		while (!demo){
			do_bar(choice);
			j = *(char*)0xdc00;
			if (j == 111)
				break;
			
			if (j == 126){
				if (choice){
					for (k=0;k<8;++k){
						do_bar(--choice);
					}
				}
			}			
			else if (j == 125){
				if (choice < 24){
					for (k=0;k<8;++k){
						do_bar(++choice);
					}
				}
			}
		}
		if (demo)			
			break;
		choice>>=3;
		
		if (choice == 1){
			team = 1;
		}
		else if (choice == 2){
			players = 1;
		}
		else if (choice == 3){
			game_irq();
			show_highscores();
			continue;
		}
		break;
	}
	fld(17);
	while (!fld_done);
	game_irq();
//	gfx_mode();
	fill();
	*(char*)0xd016 = 0x10;
	delay (35);
	if (demo){
		txt_mode();
		print2x2_centered("demo mode",7,8,10);
		delay(255);
	}
}

void all_done(void){
	txt_mode();
	print2x2_centered("that's it",7,8,10);
	print2x2_centered("no more levels!",10,2,12);
	wait_for_key_or_joy();
}

void level_up_screen(void){
	txt_mode();
	sprintf(str_dummy,"level %02d",level);
	print2x2_centered(str_dummy,6,14,6);
	print2x2_centered(mssg[level-1],3,1,8);
	fill_matrix();
}

void time_out_screen(void){
	char *s,i,l,p;
	char c = 0;

	if (demo)
		return;
	
	for (p=0;p<players+1;++p){
		for (i=0;i<10;++i){
			if (score[p] > highscore[i].score)
				break;
		}
		if (i != 10){
			for (l=9;l>i;--l){
				strcpy(highscore[l].name,highscore[l-1].name);
				highscore[l].score = highscore[l-1].score;
				highscore[l].level = highscore[l-1].level;
			}
			txt_mode();
			init_msx(5);
			if (team)
				sprintf(str_dummy,"well done, team!");
			else
				sprintf(str_dummy,"well done player %d",p+1);
			print2x2_centered(str_dummy,7,8,8);
			sprintf(str_dummy,"#%d score: %06lu",i+1,score[p]);
			print2x2_centered(str_dummy,10,2,10);
			print2x2_centered("enter your name:",4,3,14);
			l = 0;
			s = highscore[i].name;
			*s = '\0';

			while(1){
				if (*(char*)0xdc00 == 111 && l == 0){
					strcpy(highscore[i].name,"mr. button");
					print2x2_centered(highscore[i].name,15,12,17);
					delay(50);
					break;
				}
				if ((c = getkey())== 13)
					break;

				else if (c == 20){
					if (l){
						*(--s) = '\0';
						--l;
					memset((char*)(0x0400 + 17*40),0xff,80);
					}
				}
				else if (!isprint(c))
					continue;
				else if (++l == 11){
					l = 10;
					continue;
				}
				else{
					*s++ = c;
					*s = '\0';
				}
				print2x2_centered(highscore[i].name,15,12,17);
			}
			highscore[i].score = score[p];
			highscore[i].level = level;
			show_highscores();
		}
	}
}

void pause_screen(void){
	txt_mode();
	print2x2_centered("paused",13,5,10);
	wait_for_key_or_joy();
	gfx_mode();
}

void __fastcall__ check_matrix(unsigned char fo){
	unsigned char i,j,x1,x2,n,s;
	unsigned char ck = 0;

	stop = 1;

	memset(backup,EMPTY_SYMB,64);
	s = 0;
	
	for (i=0;i<8;++i){
		for (x1=0;x1<6;++x1){
			x2 = x1 + 1;
			while (matrix[i][x1] == matrix[i][x2] && x2 < 8) ++x2;
			if (x2 - x1 > 2){
				for (j=x1;j<x2;++j){
					backup[i][j] = matrix[i][j];
				}
				n = x2 - x1 - 3;
				if ((sc = 10*level << n << (fo-1)) >= 999) sc = 999;
				print_num(score[pl]+=sc,6,28,22 - (players<<1) + (pl<<1));
				
				scores[s].num = sc;
				scores[s].x = XOFFS+x1*3 + x_offsets[n];
				scores[s].y = i*3+1;
				++s;
			}
			if ((x1 = x2-1) >= 6)
				break;
		}
	}
	for (j=0;j<8;++j){
		for (x1=0;x1<6;++x1){
			x2 = x1 + 1;
			while (matrix[x1][j] == matrix[x2][j] && x2 < 8) ++x2;
			if (x2 - x1 > 2){
				for (i=x1;i<x2;++i){
					backup[i][j] = matrix[i][j];
				}
				n = x2 -x1 - 3;
				if ((sc = 10*level << n << (fo-1)) >= 999) sc= 999;
				print_num(score[pl]+=sc,6,28,22 - (players<<1) + (pl<<1));
				scores[s].num = sc;
				scores[s].x = XOFFS + j*3;
				scores[s].y = x1*3 + y_offsets[n];
				++s;
			}
			if ((x1 = x2-1) >= 6)
				break;
		}
	}

	for (i=0;i<8;++i){
		for (j=0;j<8;++j){
			if (backup[i][j] != EMPTY_SYMB){
				ck = chk_flg = 1;
				print3x3(backup[i][j]+8,j,i);
			}
		}
	}
	
	if (ck)
		delay(40);
	
	for (i=0;i<8;++i){
		for(j=0;j<8;++j){
			if (backup[i][j] != EMPTY_SYMB){
				print3x3(EMPTY_SYMB,j,i);
				matrix[i][j] = EMPTY_SYMB;
				if ((time1 += time_bonus[level-1]*fo*TIME_BONUS) > 319) 
					time1 = 319;
				if (hits[backup[i][j]])
					--hits[backup[i][j]];
				display_time();
			}
		}
	}
	for (n=0;n<s;++n){
		plot_score(scores[n].num,scores[n].x,scores[n].y);
	}
	if (team != 0 && fo == 1){
		tt ^=1;
		*(char*)0xd02e ^= 3;
	}
	
	if (ck){
		print_hits();
		delay(18);
		move_matrix();
		check_matrix(++fo);
	}
	stop = 0;
}

void __fastcall__ swap(char x, char y,char xswap,char yswap){
	char i,j,c1,c2,x1,y1;
	
	x1 = x + xswap;
	y1 = y + yswap;

	if (matrix[y1][x1] == JOKER_SYMB)
		kill_joker();
	
	clone(y,x,0);
	clone(y1,x1,1);
	c1 = matrix[y1][x1];
	c2 = matrix[y][x];

	print3x3(EMPTY_SYMB,x,y);
	print3x3(EMPTY_SYMB,x1,y1);
	
	for (i=0;i<24;++i){
		vic->spr1_y -= yswap;
		vic->spr0_y += yswap;
		vic->spr1_x -= xswap;
		vic->spr0_x += xswap;
		for (j=0;j<SWAP_DELAY;++j);
	}
	matrix[y][x] = c1;
	matrix[y1][x1] = c2;
	print3x3(c1,x,y);
	print3x3(c2,x1,y1);

	
	chk_flg = 0;
	vic->spr_ena  &= 252;
	check_matrix(1);

	if (chk_flg == 0){ //no success in swapping, then swap back
		vic->spr_ena |= 3;
		print3x3(EMPTY_SYMB,x,y);
		print3x3(EMPTY_SYMB,x1,y1);
		for (i=0;i<24;++i){
			vic->spr1_y += yswap;
			vic->spr0_y -= yswap;
			vic->spr1_x += xswap;
			vic->spr0_x -= xswap;
			for (j=0;j<SWAP_DELAY;++j);
		}
		matrix[y][x] = c2;
		matrix[y1][x1] = c1;
		print3x3(c1,x1,y1);
		print3x3(c2,x,y);
		vic->spr_ena &= 252;
	}
	else{		//success in swapping, then check if moves are possible now.
		no_more_moves_flag = !(check_moves());
	}
}


void __fastcall__ joker_hit(char pl){
	char i,j;

	stop = 1;
	kill_joker();
	matrix[joker_y][joker_x] = joker_tmp;
	sc = level*10;
	for (i=0;i<8;++i){
		for(j=0;j<8;++j){
			if (matrix[i][j] == joker_tmp){
				print3x3(matrix[i][j]+8,j,i);
			}
		}
	}
	delay(20);
	for (i=0;i<8;++i){
		for(j=0;j<8;++j){
			if (matrix[i][j] == joker_tmp){
				if (hits[joker_tmp]){
					--hits[joker_tmp];
					print_hits();
				}
				print3x3(matrix[i][j]=EMPTY_SYMB,j,i);
				plot_score(sc,XOFFS+3*j,3*i+1);
				print_num(score[pl]+=sc,6,28,22-(players<<1)+(pl<<1));
				}
			}
	}
	move_matrix();
	check_matrix(1);
	stop = 0;
}


void main(void){
	char i,joker_runtime,j1,j2;

	*(char*)0x0328 = 0xfc;	//block run/stop
	cputc(0x8);		//block shift-cbm

//	*(char*)0xd020 = 0x03;
//	cgetc();
	
	clrscr();
	setgfx(0x0428);
	revers(1);textcolor(15);cputsxy(5,11,"[l]oad or [r]eset highscores?");
	
	if (yesno()){
		load_hs();
	}
	else{
		for(i=0;i<10;++i){
			strcpy (highscore[i].name,"----------");
			highscore[i].level = 0;
			highscore[i].score = 0;
		}
	}

	while (1){
		ass_setup();

		// Copy Bitmap Data to $E000
		memmove((char*)0xe000,&bmp_data,LINES*320);
		// Copy color data (???) to $CC00
		memmove((char*)0xcc00,(char*)(&bmp_data + LINES*320),LINES*40);

		title_screen();

		memset((char*)0xdbc0,15,40);
		
		level = score[0] = xpos1 = ypos1 = joker = time_out = no_more_moves_flag = 0;
		if (players){
			xpos2 = 1; ypos2 = score[1] = 0;
		}
		
		time1 = 160;
		animals = 7;

		while (1){
			if (time_out){
				stop = 1;
				vic->spr_ena = 0;
				init_msx(4);
				if (joker==0){
					check_moves();

					if (pm_x1 == pm_x2){
						clone(pm_y1+1,pm_x1,1);
						print3x3(EMPTY_SYMB,pm_x1,pm_y1+1);
					}
					else{
						clone(pm_y1,pm_x1+1,1);
						print3x3(EMPTY_SYMB,pm_x1+1,pm_y1);
					}
					clone(pm_y1,pm_x1,0);
					print3x3(EMPTY_SYMB,pm_x1,pm_y1);
					vic->spr_ena = 3;

					while (*(char*)0xdc00 != 111){
						vic->spr_ena ^= 3;
						delay(30);
					}
				}
				else{
					while(*(char*)0xdc00 != 111);
					//kill_joker();
				}
				broesel();
				time_out_screen();
				break;
			}

			//check for level up
			for (i=0;i<animals;++i){
				if (hits[i])
					break;
			}
			
			if (level == 0 || i == animals){
				stop = 1;
				kill_joker();
				init_msx(((level%2)>>1) + 3);
				if (++level != 1){
					broesel();
				}
				if (level == 5){
					animals = 8;
				}
				if (level == 17){
					all_done();
					time_out_screen();
					break;
				}

				xpos1 = 3; ypos1 = 3;
				vic->spr7_x = 39+3*24;
				vic->spr7_y = 50+3*24;
				if (players){
					xpos2 = ypos2 = 4;
					vic->spr6_x = 39+4*24;
					vic->spr6_y = 50+4*24;
				}
				else{
					vic->spr6_x = vic->spr6_y = 0;
				}
				memset(hits,(level+2),8);

				level_up_screen();
				init_msx(~level%2);
				print_matrix();
				timer_delay = level_time[level-1];
				memset((char*)0xdbc0,0x0f,40);
				stop = no_more_moves_flag = key = 0;
			}
			if (no_more_moves_flag){
				stop = 1;
				no_more_moves();
				print_matrix();
				stop = no_more_moves_flag = 0;
			}
			if (!isstop()){
				stop = 1;
				//kill_joker();
				memcpy(backup,matrix,64);
				broesel();
				pause_screen();
				memcpy(matrix,backup,64);
				print_matrix();
				stop = 0;
			}
			if (key == CH_F8){
				stop = 1;
				//kill_joker();
				key = 0;
				broesel();
				break;
			}
			// if a joker exists, check its runtime and destroy if needed
			if(joker == 1 && (clock() - jok1)/CLOCKS_PER_SEC >= joker_runtime){
				kill_joker();
				if (!check_moves()){
					stop = 1;
					no_more_moves();
					print_matrix();
					stop = no_more_moves_flag = 0;
				}
			}

					

			// if no joker exists, create one on random number
			if (joker == 0 && random() == 0xea && random() >= 0xff){
				joker = 1;
				random(); random();
				joker_x = random() & 7;
				joker_y = random() & 7;
				matrix[joker_y][joker_x] = JOKER_SYMB;
				while ((joker_runtime = random() & 7) < 3);				
				jok1 = clock();
			}
			
			// joystick
			if (demo){
				if (*(char*)0xdc00 == 111 || *(char*)0xdc01 == 239){
					//kill_joker();
					broesel();
					break;
				}
 				if (cue_max == 0){
					if (pm_x1 > xpos1){
						for (i=0;i<(pm_x1-xpos1);++i)
							put2cue(119);
					}
					else{
						for (i=0;i<(xpos1-pm_x1);++i)
							put2cue(123);
					}
					if (pm_y1 > ypos1){
						for (i=0;i<(pm_y1-ypos1);++i)
							put2cue(125);
					}
					else{
						for(i=0;i<(ypos1-pm_y1);++i)
							put2cue(126);
					}
				}
			       	while (cue_max);
				delay(50);
//				s_temp = score[0];
				swap (xpos1,ypos1,pm_x2-pm_x1,pm_y2-pm_y1);
				/*				
				if (score[0] == s_temp){
					vic->bordercolor++;
					while(1);
				}
				*/
				
				delay(50);
				continue;
			}
			if((j1 = *(char*)(0xdc00 + tt)&0x7f) != nothing){
				pl = 0;
				if (j1 == fire_up){
					if (ypos1) swap (xpos1,ypos1,0,-1);
				}
				if (j1 == fire_down){
					if (ypos1 < 7) swap(xpos1,ypos1,0,1);
				}
				if (j1 == fire_left){
					if (xpos1) swap (xpos1,ypos1,-1,0);
				}
				if (j1 == fire_right){
					if (xpos1 < 7) swap (xpos1,ypos1,1,0);
				}
				if (j1 == 111){
					if (matrix[ypos1][xpos1] == JOKER_SYMB){
						joker_hit(pl);
					}
				}
			}
			if (players){
				if((j2 = *(char*)0xdc01) != 255){
					pl = 1;
					if (j2 == 238){
						if (ypos2) swap (xpos2,ypos2,0,-1);
					}
					if (j2 == 237){
						if (ypos2 < 7) swap(xpos2,ypos2,0,1);
					}
					if (j2 == 235){
						if (xpos2) swap (xpos2,ypos2,-1,0);
					}
					if (j2 == 231){
						if (xpos2 < 7) swap (xpos2,ypos2,1,0);
					}
					if (j2 == 239){
						if (matrix[ypos2][xpos2] == JOKER_SYMB){
							joker_hit(pl);
						}
					}
				}
			}
		}	
	}
}

