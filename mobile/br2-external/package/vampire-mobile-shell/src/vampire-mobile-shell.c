#define _POSIX_C_SOURCE 200809L
#include <SDL.h>
#include <SDL_ttf.h>
#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/utsname.h>
#include <unistd.h>

#define APP_COUNT 6
static const char *app_names[APP_COUNT] = {"SYSTEM", "NETWORK", "DISPLAY", "TERMINAL", "POWER", "ABOUT"};
static const char *app_desc[APP_COUNT] = {
    "Kernel and device information", "Network interfaces and status",
    "Display and touch input devices", "Return to the Linux console",
    "Restart or power off this device", "About Vampire Mobile OS"
};
static SDL_Window *window;
static SDL_Renderer *renderer;
static TTF_Font *font = NULL;
static TTF_Font *small_font = NULL;
static SDL_Rect cards[APP_COUNT];
static SDL_Rect back_button;
static SDL_Rect action_one;
static SDL_Rect action_two;
static int screen_w = 480, screen_h = 800, page = -1, power_confirm = 0, power_choice = 0;
static int running = 1;

static SDL_Color color(Uint8 r, Uint8 g, Uint8 b) { SDL_Color c={r,g,b,255}; return c; }
static void fill(SDL_Rect r, SDL_Color c) { SDL_SetRenderDrawColor(renderer,c.r,c.g,c.b,c.a); SDL_RenderFillRect(renderer,&r); }
static void stroke(SDL_Rect r, SDL_Color c) { SDL_SetRenderDrawColor(renderer,c.r,c.g,c.b,c.a); SDL_RenderDrawRect(renderer,&r); }
static void label(TTF_Font *f, const char *value, int x, int y, SDL_Color c) {
    if (!f || !value) return;
    SDL_Surface *surface=TTF_RenderUTF8_Blended(f,value,c);
    if (!surface) return;
    SDL_Texture *texture=SDL_CreateTextureFromSurface(renderer,surface);
    if (texture) {
        SDL_Rect dst={x,y,surface->w,surface->h};
        SDL_RenderCopy(renderer,texture,NULL,&dst);
        SDL_DestroyTexture(texture);
    }
    SDL_FreeSurface(surface);
}
static void centered(TTF_Font *f,const char *value,int cx,int y,SDL_Color c) {
    if(!f||!value)return;
    int w=0,h=0; TTF_SizeUTF8(f,value,&w,&h); label(f,value,cx-w/2,y,c);
}
static void button(SDL_Rect r,const char *title,int selected) {
    fill(r,selected?color(137,27,53):color(35,27,43));
    stroke(r,color(103,74,94));
    centered(small_font,title,r.x+r.w/2,r.y+(r.h-16)/2,color(255,247,251));
}
static void list_directory(const char *path,char *out,size_t size) {
    DIR *dir=opendir(path);
    if(!dir){snprintf(out,size,"Not available on this device.");return;}
    size_t used=0; struct dirent *entry;
    while((entry=readdir(dir))!=NULL && used+2<size) {
        if(entry->d_name[0]=='.')continue;
        int n=snprintf(out+used,size-used,"%s%s",used?", ":"",entry->d_name);
        if(n<0)break;
        if((size_t)n>=size-used){used=size-1;break;}
        used+=(size_t)n;
    }
    closedir(dir);
    if(!used)snprintf(out,size,"No devices detected.");
}
static void system_details(char *out,size_t size) {
    struct utsname u;
    if(uname(&u)==0)snprintf(out,size,"Architecture: %s\nKernel: %s\nRelease: %s\nHost: %s",u.machine,u.sysname,u.release,u.nodename);
    else snprintf(out,size,"System information is unavailable.");
}
static void network_details(char *out,size_t size) { list_directory("/sys/class/net",out,size); }
static void display_details(char *out,size_t size) {
    char drm[512],input[512];
    list_directory("/sys/class/drm",drm,sizeof(drm));
    list_directory("/sys/class/input",input,sizeof(input));
    snprintf(out,size,"Display devices: %s\n\nInput devices: %s",drm,input);
}
static void draw_background(void) {
    for(int y=0;y<screen_h;y+=8) {
        float p=(float)y/(float)(screen_h?screen_h:1);
        Uint8 r=(Uint8)(12+20*p),g=(Uint8)(8+3*p),b=(Uint8)(19+13*p);
        fill((SDL_Rect){0,y,screen_w,8},color(r,g,b));
    }
}
static void draw_home(void) {
    draw_background();
    label(font,"VAMPIRE",24,24,color(255,255,255));
    label(small_font,"MOBILE OS  /  ARM64",26,64,color(232,139,157));
    time_t now=time(NULL); struct tm *tm_now=localtime(&now); char clock_text[32]="--:--";
    if(tm_now)strftime(clock_text,sizeof(clock_text),"%H:%M",tm_now);
    label(font,clock_text,24,104,color(255,255,255));
    label(small_font,"TOUCH-FIRST SYSTEM PREVIEW",26,154,color(191,176,196));
    int cols=screen_w<620?2:3, gap=14, margin=22;
    int card_w=(screen_w-2*margin-(cols-1)*gap)/cols;
    int card_h=screen_h<620?104:126;
    int start_y=screen_h<620?205:225;
    for(int i=0;i<APP_COUNT;i++) {
        int row=i/cols,col=i%cols;
        SDL_Rect r={margin+col*(card_w+gap),start_y+row*(card_h+gap),card_w,card_h};
        cards[i]=r;
        fill(r,color(32,24,40)); stroke(r,color(90,61,82));
        SDL_Rect icon={r.x+14,r.y+14,42,42}; fill(icon,color(130,29,55));
        char initials[3]={app_names[i][0],app_names[i][1]?app_names[i][1]:' ',0};
        centered(font,initials,icon.x+icon.w/2,icon.y+7,color(255,255,255));
        label(small_font,app_names[i],r.x+14,r.y+68,color(255,248,251));
        label(small_font,app_desc[i],r.x+14,r.y+88,color(183,169,190));
    }
    centered(small_font,"VAMPIRE OS  •  DEVELOPMENT BUILD",screen_w/2,screen_h-38,color(154,137,163));
}
static void draw_detail(void) {
    draw_background();
    back_button=(SDL_Rect){20,22,88,42};
    button(back_button,"BACK",0);
    centered(font,app_names[page],screen_w/2,94,color(255,255,255));
    centered(small_font,app_desc[page],screen_w/2,136,color(210,194,215));
    SDL_Rect panel={20,184,screen_w-40,screen_h-270};
    fill(panel,color(31,24,39)); stroke(panel,color(92,63,84));
    char details[1400]="";
    if(page==0)system_details(details,sizeof(details));
    else if(page==1)network_details(details,sizeof(details));
    else if(page==2)display_details(details,sizeof(details));
    else if(page==3)snprintf(details,sizeof(details),"The terminal runs on the Linux console.\nChoose Open Console to leave the graphical shell.\nYour session remains available on the serial/TTY console.");
    else if(page==4)snprintf(details,sizeof(details),power_confirm?"Confirm the selected power action.":"Power actions require a second confirmation.");
    else snprintf(details,sizeof(details),"Vampire Mobile OS\nA touch-first Linux mobile shell.\nTarget: generic ARM64 QEMU virt.\nThis preview does not claim phone hardware support.");
    int y=panel.y+24;
    char *line=strtok(details,"\n");
    while(line && y<panel.y+panel.h-80) { label(small_font,line,panel.x+20,y,color(238,229,240)); y+=29; line=strtok(NULL,"\n"); }
    action_one=(SDL_Rect){panel.x+16,panel.y+panel.h-58,(panel.w-44)/2,42};
    action_two=(SDL_Rect){panel.x+28+action_one.w,panel.y+panel.h-58,(panel.w-44)/2,42};
    if(page==3)button(action_one,"OPEN CONSOLE",0);
    else if(page==4) {
        button(action_one,"RESTART",0);
        button(action_two,"POWER OFF",0);
        if(power_confirm)centered(small_font,"CONFIRM BY TAPPING AGAIN",screen_w/2,panel.y+panel.h-92,color(255,159,174));
    } else button(action_one,"REFRESH",0);
}
static void open_console(void) {
    SDL_Quit(); TTF_Quit();
    execl("/bin/sh","sh",(char *)NULL);
    _exit(127);
}
static void activate(int x,int y) {
    if(page<0) {
        for(int i=0;i<APP_COUNT;i++)if(x>=cards[i].x&&x<cards[i].x+cards[i].w&&y>=cards[i].y&&y<cards[i].y+cards[i].h){page=i;power_confirm=0;return;}
        return;
    }
    if(x>=back_button.x&&x<back_button.x+back_button.w&&y>=back_button.y&&y<back_button.y+back_button.h){page=-1;power_confirm=0;return;}
    if(page==3&&x>=action_one.x&&x<action_one.x+action_one.w&&y>=action_one.y&&y<action_one.y+action_one.h){open_console();return;}
    if(page==4) {
        if(x>=action_one.x&&x<action_one.x+action_one.w&&y>=action_one.y&&y<action_one.y+action_one.h) {
            if(power_confirm&&power_choice==1) { SDL_Quit(); TTF_Quit(); execl("/sbin/reboot","reboot",(char *)NULL); _exit(127); }
            power_confirm=1; power_choice=1; return;
        }
        if(x>=action_two.x&&x<action_two.x+action_two.w&&y>=action_two.y&&y<action_two.y+action_two.h) {
            if(power_confirm&&power_choice==2) { SDL_Quit(); TTF_Quit(); execl("/sbin/poweroff","poweroff",(char *)NULL); _exit(127); }
            power_confirm=1; power_choice=2; return;
        }
    }
}
int main(void) {
    SDL_setenv("SDL_VIDEODRIVER","fbcon",0);
    SDL_setenv("SDL_FBDEV","/dev/fb0",0);
    if(SDL_Init(SDL_INIT_VIDEO|SDL_INIT_EVENTS)!=0){fprintf(stderr,"Vampire Mobile UI: SDL init failed: %s\n",SDL_GetError());return 1;}
    if(TTF_Init()!=0){fprintf(stderr,"Vampire Mobile UI: font subsystem failed: %s\n",TTF_GetError());SDL_Quit();return 1;}
    const char *font_paths[]={"/usr/share/fonts/dejavu/DejaVuSans.ttf","/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf","/usr/share/fonts/TTF/DejaVuSans.ttf",NULL};
    for(int i=0;font_paths[i]&&!font;i++)font=TTF_OpenFont(font_paths[i],28);
    for(int i=0;font_paths[i]&&!small_font;i++)small_font=TTF_OpenFont(font_paths[i],15);
    if(!font||!small_font){fprintf(stderr,"Vampire Mobile UI: DejaVu font not found.\n");TTF_Quit();SDL_Quit();return 1;}
    window=SDL_CreateWindow("Vampire Mobile OS",SDL_WINDOWPOS_UNDEFINED,SDL_WINDOWPOS_UNDEFINED,480,800,SDL_WINDOW_FULLSCREEN_DESKTOP);
    if(!window){fprintf(stderr,"Vampire Mobile UI: window creation failed: %s\n",SDL_GetError());TTF_CloseFont(font);TTF_CloseFont(small_font);TTF_Quit();SDL_Quit();return 1;}
    renderer=SDL_CreateRenderer(window,-1,SDL_RENDERER_SOFTWARE);
    if(!renderer){fprintf(stderr,"Vampire Mobile UI: renderer creation failed: %s\n",SDL_GetError());SDL_DestroyWindow(window);TTF_CloseFont(font);TTF_CloseFont(small_font);TTF_Quit();SDL_Quit();return 1;}
    SDL_GetRendererOutputSize(renderer,&screen_w,&screen_h);
    if(screen_w<320||screen_h<320){screen_w=480;screen_h=800;}
    while(running) {
        SDL_Event event;
        while(SDL_PollEvent(&event)) {
            if(event.type==SDL_QUIT)running=0;
            else if(event.type==SDL_KEYDOWN) {
                if(event.key.keysym.sym==SDLK_ESCAPE||event.key.keysym.sym==SDLK_BACKSPACE){page=-1;power_confirm=0;}
                else if(event.key.keysym.sym==SDLK_t)open_console();
                else if(event.key.keysym.sym==SDLK_q)running=0;
            } else if(event.type==SDL_MOUSEBUTTONDOWN)activate(event.button.x,event.button.y);
            else if(event.type==SDL_FINGERDOWN)activate((int)(event.tfinger.x*screen_w),(int)(event.tfinger.y*screen_h));
        }
        if(page<0)draw_home();else draw_detail();
        SDL_RenderPresent(renderer);
        SDL_Delay(80);
    }
    SDL_DestroyRenderer(renderer);SDL_DestroyWindow(window);
    if(font)TTF_CloseFont(font);if(small_font)TTF_CloseFont(small_font);
    TTF_Quit();SDL_Quit();return 0;
}
