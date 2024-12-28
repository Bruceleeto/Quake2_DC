#include <kos.h>
#include "ref_gl/gl_local.h"
#include "client/keys.h"
#include "quake2.h"
#include <kos/thread.h>
#include <malloc.h>
#include <string.h>
#include <stdio.h>
#include <dc/maple/keyboard.h>

#define MAIN_STACK_SIZE (32 * 1024)  // 64KB for main thread
#define RAM_UPDATE_INTERVAL 5000      // 5 seconds in milliseconds
KOS_INIT_FLAGS(INIT_DEFAULT | INIT_NET);

static int _width = 640;
static int _height = 480;
int _old_button_state = 0;
static unsigned long systemRam = 0x00000000;
static unsigned long elfOffset = 0x8c000000;  // Dreamcast specific
static unsigned long stackSize = 0x00000000;
static unsigned long lastRamCheck = 0;

extern unsigned long end;
extern unsigned long start;








// Map Dreamcast keyboard scancodes to Quake 2 key codes
static int keyboard_map[] = {
    [KBD_KEY_A] = 'a',
    [KBD_KEY_B] = 'b',
    [KBD_KEY_C] = 'c',
    [KBD_KEY_D] = 'd',
    [KBD_KEY_E] = 'e',
    [KBD_KEY_F] = 'f',
    [KBD_KEY_G] = 'g',
    [KBD_KEY_H] = 'h',
    [KBD_KEY_I] = 'i',
    [KBD_KEY_J] = 'j',
    [KBD_KEY_K] = 'k',
    [KBD_KEY_L] = 'l',
    [KBD_KEY_M] = 'm',
    [KBD_KEY_N] = 'n',
    [KBD_KEY_O] = 'o',
    [KBD_KEY_P] = 'p',
    [KBD_KEY_Q] = 'q',
    [KBD_KEY_R] = 'r',
    [KBD_KEY_S] = 's',
    [KBD_KEY_T] = 't',
    [KBD_KEY_U] = 'u',
    [KBD_KEY_V] = 'v',
    [KBD_KEY_W] = 'w',
    [KBD_KEY_X] = 'x',
    [KBD_KEY_Y] = 'y',
    [KBD_KEY_Z] = 'z',
    [KBD_KEY_1] = '1',
    [KBD_KEY_2] = '2',
    [KBD_KEY_3] = '3',
    [KBD_KEY_4] = '4',
    [KBD_KEY_5] = '5',
    [KBD_KEY_6] = '6',
    [KBD_KEY_7] = '7',
    [KBD_KEY_8] = '8',
    [KBD_KEY_9] = '9',
    [KBD_KEY_0] = '0',
    [KBD_KEY_ENTER] = K_ENTER,
    [KBD_KEY_ESCAPE] = K_ESCAPE,
    [KBD_KEY_BACKSPACE] = K_BACKSPACE,
    [KBD_KEY_TAB] = K_TAB,
    [KBD_KEY_SPACE] = K_SPACE,
    [KBD_KEY_MINUS] = '-',
    [KBD_KEY_PLUS] = '=',
    [KBD_KEY_LBRACKET] = '[',
    [KBD_KEY_RBRACKET] = ']',
    [KBD_KEY_BACKSLASH] = '\\',
    [KBD_KEY_SEMICOLON] = ';',
    [KBD_KEY_QUOTE] = '\'',
    [KBD_KEY_TILDE] = '`',
    [KBD_KEY_COMMA] = ',',
    [KBD_KEY_PERIOD] = '.',
    [KBD_KEY_SLASH] = '/',
    [KBD_KEY_F1] = K_F1,
    [KBD_KEY_F2] = K_F2,
    [KBD_KEY_F3] = K_F3,
    [KBD_KEY_F4] = K_F4,
    [KBD_KEY_F5] = K_F5,
    [KBD_KEY_F6] = K_F6,
    [KBD_KEY_F7] = K_F7,
    [KBD_KEY_F8] = K_F8,
    [KBD_KEY_F9] = K_F9,
    [KBD_KEY_F10] = K_F10,
    [KBD_KEY_F11] = K_F11,
    [KBD_KEY_F12] = K_F12,
    [KBD_KEY_INSERT] = K_INS,
    [KBD_KEY_HOME] = K_HOME,
    [KBD_KEY_PGUP] = K_PGUP,
    [KBD_KEY_DEL] = K_DEL,
    [KBD_KEY_END] = K_END,
    [KBD_KEY_PGDOWN] = K_PGDN,
    [KBD_KEY_RIGHT] = K_RIGHTARROW,
    [KBD_KEY_LEFT] = K_LEFTARROW,
    [KBD_KEY_DOWN] = K_DOWNARROW,
    [KBD_KEY_UP] = K_UPARROW
};

// Track previous keyboard state to detect key releases
static uint8 prev_matrix[MAX_KBD_KEYS] = {0};

void HandleKeyboard(void) {
    int i;
    MAPLE_FOREACH_BEGIN(MAPLE_FUNC_KEYBOARD, kbd_state_t, state)
        // Handle modifier keys
        if(state->shift_keys & KBD_MOD_LCTRL)
            Quake2_SendKey(K_CTRL, true);
        else
            Quake2_SendKey(K_CTRL, false);
            
        if(state->shift_keys & (KBD_MOD_LSHIFT | KBD_MOD_RSHIFT))
            Quake2_SendKey(K_SHIFT, true);
        else
            Quake2_SendKey(K_SHIFT, false);
            
        if(state->shift_keys & (KBD_MOD_LALT | KBD_MOD_RALT))
            Quake2_SendKey(K_ALT, true);
        else
            Quake2_SendKey(K_ALT, false);

        // Check all possible keys
        for( i = 0; i < MAX_KBD_KEYS; i++) {
            // Key press
            if(state->matrix[i] && !prev_matrix[i]) {
                if(keyboard_map[i]) {
                    Quake2_SendKey(keyboard_map[i], true);
                }
            }
            // Key release
            else if(!state->matrix[i] && prev_matrix[i]) {
                if(keyboard_map[i]) {
                    Quake2_SendKey(keyboard_map[i], false);
                }
            }
            prev_matrix[i] = state->matrix[i];
        }
    MAPLE_FOREACH_END()
}


static void init_thread_stack(void) {
    kthread_t *current = thd_get_current();
    if (current) {
        void *new_stack = malloc(MAIN_STACK_SIZE);
        if (new_stack) {
            current->stack = new_stack;
            current->stack_size = MAIN_STACK_SIZE;
            current->flags |= THD_OWNS_STACK;
        }
    }
}

unsigned long getFreeRam(void) {
    struct mallinfo mi = mallinfo();
    return systemRam - (mi.usmblks + stackSize);
}

void setSystemRam(void) {
    // Dreamcast has 16MB RAM
    systemRam = 0x8d000000 - 0x8c000000;
    stackSize = (int)&end - (int)&start + ((int)&start - elfOffset);
}

unsigned long getSystemRam(void) {
    return systemRam;
}

unsigned long getUsedRam(void) {
    return (systemRam - getFreeRam());
}

void checkAndDisplayRamStatus(void) {
    unsigned long currentTime = timer_ms_gettime64();
    if (currentTime - lastRamCheck >= RAM_UPDATE_INTERVAL) {
        printf("\nRAM Status:\n");
        printf("Total: %.2f MB, Free: %.2f MB, Used: %.2f MB\n",
               getSystemRam() / (1024.0 * 1024.0),
               getFreeRam() / (1024.0 * 1024.0),
               getUsedRam() / (1024.0 * 1024.0));
        lastRamCheck = currentTime;
        malloc_stats();
        //Hunk_Stats_f();
        Z_Stats_f(); 
    }
}
// Quake 2 interface functions remain the same
qboolean GLimp_InitGL(void) { return true; }

static void setupWindow(qboolean fullscreen) { }

int GLimp_SetMode(int *pwidth, int *pheight, int mode, qboolean fullscreen) {
    int width = 0;
    int height = 0;

    ri.Con_Printf(PRINT_ALL, "Initializing OpenGL display\n");
    ri.Con_Printf(PRINT_ALL, "...setting mode %d:", mode);

    if (!ri.Vid_GetModeInfo(&width, &height, mode)) {
        ri.Con_Printf(PRINT_ALL, " invalid mode\n");
        return rserr_invalid_mode;
    }

    ri.Con_Printf(PRINT_ALL, " %d %d\n", width, height);

    _width = width;
    _height = height;
    *pwidth = width;
    *pheight = height;
    ri.Vid_NewWindow(width, height);
    return rserr_ok;
}

void GLimp_Shutdown(void) { }

int GLimp_Init(void *hinstance, void *wndproc) {
    setupWindow(false);
    return true;
}

void GLimp_BeginFrame(float camera_seperation) { }

void GLimp_EndFrame(void) {
    glFlush();
    glKosSwapBuffers();
}

void GLimp_AppActivate(qboolean active) { }

int QG_Milliseconds(void) {
    return timer_ms_gettime64();
}

void QG_CaptureMouse(void) { }
void QG_ReleaseMouse(void) { }

void HandleInput(void) {
    MAPLE_FOREACH_BEGIN(MAPLE_FUNC_CONTROLLER, cont_state_t, state)
        int i;
        int button_state = 0;
        
        if (state->buttons & CONT_DPAD_UP)
            Quake2_SendKey(K_UPARROW, true);
        else
            Quake2_SendKey(K_UPARROW, false);
            
        if (state->buttons & CONT_DPAD_DOWN)
            Quake2_SendKey(K_DOWNARROW, true);
        else
            Quake2_SendKey(K_DOWNARROW, false);
            
        if (state->buttons & CONT_DPAD_LEFT)
            Quake2_SendKey(K_LEFTARROW, true);
        else
            Quake2_SendKey(K_LEFTARROW, false);
            
        if (state->buttons & CONT_DPAD_RIGHT)
            Quake2_SendKey(K_RIGHTARROW, true);
        else
            Quake2_SendKey(K_RIGHTARROW, false);

        if (state->buttons & CONT_A)
            button_state |= (1 << 0);
            
        if (state->buttons & CONT_B)
            button_state |= (1 << 1);
            
        if (state->buttons & CONT_X)
            Quake2_SendKey(K_ENTER, true);
        else
            Quake2_SendKey(K_ENTER, false);
            
        if (state->buttons & CONT_Y)
            Quake2_SendKey(K_ESCAPE, true);
        else
            Quake2_SendKey(K_ESCAPE, false);
            
        if (state->buttons & CONT_START)
            ri.Cmd_ExecuteText(EXEC_NOW, "quit");

        for (i = 0; i < 2; i++) {
            if ((button_state & (1<<i)) && !(_old_button_state & (1<<i)))
                Quake2_SendKey(K_MOUSE1 + i, true);
                
            if (!(button_state & (1<<i)) && (_old_button_state & (1<<i)))
                Quake2_SendKey(K_MOUSE1 + i, false);
        }
        
        _old_button_state = button_state;
    MAPLE_FOREACH_END()
}

void QG_GetMouseDiff(int* dx, int* dy) {
    MAPLE_FOREACH_BEGIN(MAPLE_FUNC_CONTROLLER, cont_state_t, state)
        *dx = state->joyx / 4;
        *dy = state->joyy / 4;
    MAPLE_FOREACH_END()
}

int main(int argc, char **argv) {
    init_thread_stack();
    setSystemRam();  // Initialize RAM tracking
    kbd_init();
    net_init(0);

    // PowerVR config
    GLdcConfig config;
    glKosInitConfig(&config);
    config.autosort_enabled = GL_TRUE;
    config.fsaa_enabled = GL_FALSE;
    config.internal_palette_format = GL_RGBA8;
    config.initial_op_capacity = 4096 * 3;
    config.initial_pt_capacity = 256 * 3;
    config.initial_tr_capacity = 1024 * 3;
    config.initial_immediate_capacity = 256 * 3;
    glKosInitEx(&config);

    printf("Initial RAM Status:\n");
    printf("Total: %lu KB, Free: %lu KB, Used: %lu KB\n",
           getSystemRam() / 1024,
           getFreeRam() / 1024,
           getUsedRam() / 1024);

    int time, oldtime, newtime;
    Quake2_Init(argc, argv);

    oldtime = QG_Milliseconds();
    while (1) {
    HandleKeyboard();   // Keyboard input
        
        do {
            newtime = QG_Milliseconds();
            time = newtime - oldtime;
        } while (time < 1);

        Quake2_Frame(time);
        checkAndDisplayRamStatus();  // Check RAM every 5 seconds
        oldtime = newtime;
        thd_pass();
    }

    return 0;
}