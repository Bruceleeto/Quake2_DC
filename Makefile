# Target configuration
TARGET = quake2.elf

.PHONY: all clean dist
all: $(TARGET)

# KOS Settings
include $(KOS_BASE)/Makefile.rules

# Check if GL is enabled
GL ?= 1

# Directory definitions
BUILDDIR = build
CLIENT_DIR = client
SERVER_DIR = server
COMMON_DIR = qcommon
OTHER_DIR = other
NET_DIR = net
SOUND_DIR = sound
NULL_DIR = null
GAME_DIR = game
REF_SOFT_DIR = ref_soft
REF_GL_DIR = ref_gl


# need to use kos ports cglm.. maybe but will use neo's modded one for now.
 #  -g0 \#
#   -s \#   For mem gains. 
# Compiler settings
CC = kos-cc
LDFLAGS += -Wl,--gc-sections -Wl,-Map=output.map -s 
CFLAGS = -std=gnu89 \
   -Dstricmp=strcasecmp \
   -DNDEBUG \
   -MMD -MP \
   -ffunction-sections \
   -fdata-sections \
   -Wno-missing-braces \
   -ffast-math \
   -fmerge-all-constants \
   -fomit-frame-pointer \
   -fno-common \
   -fno-exceptions \
   -fno-unwind-tables \
   -Wno-dangling-pointer \
   -Wno-aggressive-loop-optimizations \
   -Wno-stringop-overflow  \
   -Wno-unused-but-set-variable \
   -Wno-array-parameter \
   -Wno-strict-aliasing \
   -Wno-uninitialized \
   -Wno-dangling-else \
   -Wno-switch \
   -Wunused-function \
   -Wlto-type-mismatch \
   -fno-asynchronous-unwind-tables \
   -fno-stack-protector \
   -fvisibility=hidden \
   -Os \
   -Wno-write-strings \
    -Ideps/cglm/include \
   $(KOS_CFLAGS)


ifeq ($(GL),1)
    CFLAGS += -DREF_GL
endif

# Libraries
KOS_LIBS +=   -lfastmem -lm 

ifeq ($(GL),1)
    KOS_LIBS += -lGL
endif

# Compilation rules
DO_CC = $(CC) $(CFLAGS) -o $@ -c $<

CLIENT_OBJS = \
	$(BUILDDIR)/client/cl_cin.o \
	$(BUILDDIR)/client/cl_ents.o \
	$(BUILDDIR)/client/cl_fx.o \
	$(BUILDDIR)/client/cl_newfx.o \
	$(BUILDDIR)/client/cl_input.o \
	$(BUILDDIR)/client/cl_inv.o \
	$(BUILDDIR)/client/cl_main.o \
	$(BUILDDIR)/client/cl_parse.o \
	$(BUILDDIR)/client/cl_pred.o \
	$(BUILDDIR)/client/cl_tent.o \
	$(BUILDDIR)/client/cl_scrn.o \
	$(BUILDDIR)/client/cl_view.o \
	$(BUILDDIR)/client/console.o \
	$(BUILDDIR)/client/keys.o \
	$(BUILDDIR)/client/menu.o \
	$(BUILDDIR)/client/snd_dma.o \
	$(BUILDDIR)/client/snd_mem.o \
	$(BUILDDIR)/client/snd_mix.o \
	$(BUILDDIR)/client/qmenu.o \
	$(BUILDDIR)/client/cmd.o \
	$(BUILDDIR)/client/cmodel.o \
	$(BUILDDIR)/client/common.o \
	$(BUILDDIR)/client/crc.o \
	$(BUILDDIR)/client/cvar.o \
	$(BUILDDIR)/client/files.o \
	$(BUILDDIR)/client/md4.o \
	$(BUILDDIR)/client/net_chan.o \
	$(BUILDDIR)/client/sv_ccmds.o \
	$(BUILDDIR)/client/sv_ents.o \
	$(BUILDDIR)/client/sv_game.o \
	$(BUILDDIR)/client/sv_init.o \
	$(BUILDDIR)/client/sv_main.o \
	$(BUILDDIR)/client/sv_send.o \
	$(BUILDDIR)/client/sv_user.o \
	$(BUILDDIR)/client/sv_world.o \
	$(BUILDDIR)/client/cd_null.o \
	$(BUILDDIR)/client/q_hunk.o \
	$(BUILDDIR)/client/vid_menu.o \
	$(BUILDDIR)/client/vid_lib.o \
	$(BUILDDIR)/client/q_system.o \
	$(BUILDDIR)/client/glob.o \
	$(BUILDDIR)/client/pmove.o

GAME_OBJS = \
	$(BUILDDIR)/game/g_ai.o \
	$(BUILDDIR)/game/p_client.o \
	$(BUILDDIR)/game/g_cmds.o \
	$(BUILDDIR)/game/g_svcmds.o \
	$(BUILDDIR)/game/g_combat.o \
	$(BUILDDIR)/game/g_func.o \
	$(BUILDDIR)/game/g_items.o \
	$(BUILDDIR)/game/g_main.o \
	$(BUILDDIR)/game/g_misc.o \
	$(BUILDDIR)/game/g_monster.o \
	$(BUILDDIR)/game/g_phys.o \
	$(BUILDDIR)/game/g_save.o \
	$(BUILDDIR)/game/g_spawn.o \
	$(BUILDDIR)/game/g_target.o \
	$(BUILDDIR)/game/g_trigger.o \
	$(BUILDDIR)/game/g_turret.o \
	$(BUILDDIR)/game/g_utils.o \
	$(BUILDDIR)/game/g_weapon.o \
	$(BUILDDIR)/game/m_actor.o \
	$(BUILDDIR)/game/m_berserk.o \
	$(BUILDDIR)/game/m_boss2.o \
	$(BUILDDIR)/game/m_boss3.o \
	$(BUILDDIR)/game/m_boss31.o \
	$(BUILDDIR)/game/m_boss32.o \
	$(BUILDDIR)/game/m_brain.o \
	$(BUILDDIR)/game/m_chick.o \
	$(BUILDDIR)/game/m_flipper.o \
	$(BUILDDIR)/game/m_float.o \
	$(BUILDDIR)/game/m_flyer.o \
	$(BUILDDIR)/game/m_gladiator.o \
	$(BUILDDIR)/game/m_gunner.o \
	$(BUILDDIR)/game/m_hover.o \
	$(BUILDDIR)/game/m_infantry.o \
	$(BUILDDIR)/game/m_insane.o \
	$(BUILDDIR)/game/m_medic.o \
	$(BUILDDIR)/game/m_move.o \
	$(BUILDDIR)/game/m_mutant.o \
	$(BUILDDIR)/game/m_parasite.o \
	$(BUILDDIR)/game/m_soldier.o \
	$(BUILDDIR)/game/m_supertank.o \
	$(BUILDDIR)/game/m_tank.o \
	$(BUILDDIR)/game/p_hud.o \
	$(BUILDDIR)/game/p_trail.o \
	$(BUILDDIR)/game/p_view.o \
	$(BUILDDIR)/game/p_weapon.o \
	$(BUILDDIR)/game/q_shared.o \
	$(BUILDDIR)/game/g_chase.o \
	$(BUILDDIR)/game/m_flash.o

# Renderer objects are conditional based on GL flag
ifeq ($(GL),1)
REF_GL_OBJS = \
	$(BUILDDIR)/ref_gl/gl_draw.o \
	$(BUILDDIR)/ref_gl/gl_image.o \
	$(BUILDDIR)/ref_gl/gl_light.o \
	$(BUILDDIR)/ref_gl/gl_mesh.o \
	$(BUILDDIR)/ref_gl/gl_model.o \
	$(BUILDDIR)/ref_gl/gl_rmain.o \
	$(BUILDDIR)/ref_gl/gl_rmisc.o \
	$(BUILDDIR)/ref_gl/gl_rsurf.o \
	$(BUILDDIR)/ref_gl/gl_warp.o \
	$(BUILDDIR)/ref_gl/qgl_system.o \
	$(BUILDDIR)/ref_gl/port_gl_sdl.o
REF_SOFT_OBJS =
REF_SOFT_SDL_OBJS =
else
REF_GL_OBJS =
REF_SOFT_OBJS = \
	$(BUILDDIR)/ref_soft/r_aclip.o \
	$(BUILDDIR)/ref_soft/r_alias.o \
	$(BUILDDIR)/ref_soft/r_bsp.o \
	$(BUILDDIR)/ref_soft/r_draw.o \
	$(BUILDDIR)/ref_soft/r_edge.o \
	$(BUILDDIR)/ref_soft/r_image.o \
	$(BUILDDIR)/ref_soft/r_light.o \
	$(BUILDDIR)/ref_soft/r_main.o \
	$(BUILDDIR)/ref_soft/r_misc.o \
	$(BUILDDIR)/ref_soft/r_model.o \
	$(BUILDDIR)/ref_soft/r_part.o \
	$(BUILDDIR)/ref_soft/r_poly.o \
	$(BUILDDIR)/ref_soft/r_polyse.o \
	$(BUILDDIR)/ref_soft/r_rast.o \
	$(BUILDDIR)/ref_soft/r_scan.o \
	$(BUILDDIR)/ref_soft/r_sprite.o \
	$(BUILDDIR)/ref_soft/r_surf.o
REF_SOFT_SDL_OBJS = $(BUILDDIR)/ref_soft/port_soft_sdl.o
endif

NET_OBJS = $(BUILDDIR)/net/net_loopback.o
SOUND_OBJS = $(BUILDDIR)/sound/snddma_null.o
PLATFORM_OBJS = $(BUILDDIR)/port_platform_unix.o

# Combine all objects
ALL_OBJS = $(CLIENT_OBJS) $(GAME_OBJS) $(REF_SOFT_OBJS) $(REF_SOFT_SDL_OBJS) $(REF_GL_OBJS) $(NET_OBJS) $(SOUND_OBJS) $(PLATFORM_OBJS)

$(TARGET): createdirs $(ALL_OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(ALL_OBJS) $(KOS_LIBS)


createdirs:
	mkdir -p $(BUILDDIR) \
		$(BUILDDIR)/client \
		$(BUILDDIR)/ref_soft \
		$(BUILDDIR)/ref_gl \
		$(BUILDDIR)/net \
		$(BUILDDIR)/sound \
		$(BUILDDIR)/game

$(BUILDDIR)/client/%.o: $(CLIENT_DIR)/%.c
	@mkdir -p $(dir $@)
	$(DO_CC)

$(BUILDDIR)/client/%.o: $(COMMON_DIR)/%.c
	@mkdir -p $(dir $@)
	$(DO_CC)

$(BUILDDIR)/client/%.o: $(SERVER_DIR)/%.c
	@mkdir -p $(dir $@)
	$(DO_CC)

$(BUILDDIR)/client/%.o: $(NULL_DIR)/%.c
	@mkdir -p $(dir $@)
	$(DO_CC)

$(BUILDDIR)/client/%.o: $(OTHER_DIR)/%.c
	@mkdir -p $(dir $@)
	$(DO_CC)

$(BUILDDIR)/game/%.o: $(GAME_DIR)/%.c
	@mkdir -p $(dir $@)
	$(DO_CC)

$(BUILDDIR)/ref_soft/%.o: $(REF_SOFT_DIR)/%.c
	@mkdir -p $(dir $@)
	$(DO_CC)

$(BUILDDIR)/ref_gl/%.o: $(REF_GL_DIR)/%.c
	@mkdir -p $(dir $@)
	$(DO_CC)

$(BUILDDIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(DO_CC)

$(BUILDDIR)/net/%.o: $(NET_DIR)/%.c
	@mkdir -p $(dir $@)
	$(DO_CC)

$(BUILDDIR)/sound/%.o: $(SOUND_DIR)/%.c
	@mkdir -p $(dir $@)
	$(DO_CC)

$(BUILDDIR)/ref_soft/port_soft_sdl.o: port_soft_sdl.c
	@mkdir -p $(dir $@)
	$(DO_CC)

$(BUILDDIR)/ref_gl/port_gl_sdl.o: port_gl_sdl.c
	@mkdir -p $(dir $@)
	$(DO_CC)

clean:
	-rm -rf $(BUILDDIR)
	-rm -f $(TARGET)

dist: $(TARGET)
	$(KOS_STRIP) $(TARGET) -n 

# Run target for dc-tool
run: $(TARGET)
	$(KOS_LOADER) $(TARGET) -n 


# CDI creation targets
CDI_NAME = "Quake II DC"
CDI_OUTPUT = quake2.cdi
SDISO_OUTPUT = q2isoldr.iso

.PHONY: cdi sdiso

cdi: $(TARGET)
	# Scramble the ELF into 1ST_READ.BIN
	scramble $(TARGET) cd/1ST_READ.BIN
	# Create CDI image with proper Dreamcast structure
	mkdcdisc \
		-n $(CDI_NAME) \
		-d cd/baseq2 \
		-f cd/IP.BIN \
		-e $(TARGET) \
		-o $(CDI_OUTPUT) \
		-N

# Create SD card compatible ISO
sdiso: cdi
	$(RM) $(SDISO_OUTPUT)
	mksdiso -h $(CDI_OUTPUT) $(SDISO_OUTPUT) -n 

# Update clean target to also clean CDI files
clean: 
	-rm -rf $(BUILDDIR)
	-rm -f $(TARGET)
	-rm -f $(CDI_OUTPUT)
	-rm -f $(SDISO_OUTPUT)
	-rm -f cd/1ST_READ.BIN