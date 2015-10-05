.include "defines.inc"


.segment "FIXED"

PROC minimap
	lda current_bank
	pha
	lda #^show_minimap
	jsr bankswitch
	jsr show_minimap & $ffff
	pla
	jsr bankswitch
	rts
.endproc

PROC back_to_game_from_minimap
	lda current_bank
	pha
	lda #0
	jsr bankswitch

	jsr update_player_sprite
	jsr update_enemy_sprites
	jsr update_effect_sprites

	LOAD_ALL_TILES $000, ui_tiles
	jsr init_status_tiles

	pla
	jsr bankswitch
	rts
.endproc


.segment "EXTRA"

PROC show_minimap
	ldx #0
palettesaveloop:
	lda active_palette, x
	sta saved_palette, x
	inx
	cpx #32
	bne palettesaveloop

	lda ppu_settings
	sta saved_ppu_settings

	jsr fade_out

	LOAD_ALL_TILES $000, ui_tiles
	LOAD_ALL_TILES MINIMAP_TILE_BACKGROUND, minimap_background_tiles
	LOAD_ALL_TILES MINIMAP_TILE_FOREST, minimap_forest_tiles
	LOAD_ALL_TILES MINIMAP_TILE_CAVE_ENTRANCE, minimap_cave_entrace_tile
	LOAD_ALL_TILES MINIMAP_TILE_ROCK, minimap_rock_tiles
	LOAD_ALL_TILES MINIMAP_TILE_BASE, minimap_base_tiles
	LOAD_ALL_TILES MINIMAP_TILE_TOWN, minimap_town_tiles
	LOAD_ALL_TILES MINIMAP_TILE_ARROWS, minimap_arrow_tiles
	LOAD_ALL_TILES MINIMAP_TILE_LAKE, minimap_lake_tiles
	LOAD_ALL_TILES MINIMAP_TILE_INDICATORS, minimap_indicator_tiles

	lda #PPUCTRL_ENABLE_NMI | PPUCTRL_NAMETABLE_2000
	sta ppu_settings

	; Draw map background
	LOAD_PTR minimap_top_row
	ldx #0
	ldy #32 + 1
	lda #30
	jsr write_tiles
	LOAD_PTR minimap_bot_row
	ldx #0
	ldy #32 + 24
	lda #30
	jsr write_tiles

	lda #32 + 2
	sta arg0
mapbackgroundloop:
	LOAD_PTR minimap_mid_row
	ldx #0
	ldy arg0
	lda #30
	jsr write_tiles

	ldy arg0
	iny
	sty arg0
	cpy #32 + 24
	bne mapbackgroundloop

	; Show options text
	lda #0
	sta arg0
	lda #16 + 13
	sta arg1
	lda #16 + 13
	sta arg3
	lda #5
	sta arg2
	lda #1
	sta arg4
	jsr set_box_palette

	lda #6
	sta arg0
	lda #16 + 13
	sta arg1
	lda #16 + 13
	sta arg3
	lda #15
	sta arg2
	lda #2
	sta arg4
	jsr set_box_palette

	LOAD_PTR resume_str
	ldx #3
	ldy #32 + 26
	jsr write_string

	LOAD_PTR save_str
	ldx #14
	ldy #32 + 26
	jsr write_string
	ldx #19
	ldy #32 + 26
	jsr write_string
	ldx #23
	ldy #32 + 26
	jsr write_string

	LOAD_PTR minimap_right_arrow
	ldx #1
	ldy #32 + 26
	lda #1
	jsr write_tiles
	LOAD_PTR minimap_left_arrow
	ldx #10
	ldy #32 + 26
	lda #1
	jsr write_tiles

	; Generate map contents.  On SNROM this will pull the cache from work RAM, on UNROM this
	; will be generated now (which is slower but there is no extra RAM).
	jsr render_minimap

	; Clear tiles that have not been visited yet
	lda #0
	sta arg1
visityloop:
	lda #0
	sta arg0
visitxloop:
	lda arg1
	asl
	asl
	sta temp
	lda arg0
	lsr
	lsr
	lsr
	clc
	adc temp
	tay

	lda arg0
	and #7
	tax

	lda (map_visited_ptr), y
	and toggle_mask, x
	bne visited

	ldx arg0
	ldy arg1
	lda #MINIMAP_TILE_ROCK + SMALL_BORDER_CENTER ; This tile is blank
	jsr write_minimap_tile

visited:
	ldx arg0
	inx
	stx arg0
	cpx #26
	bne visitxloop

	ldy arg1
	iny
	sty arg1
	cpy #22
	bne visityloop

	; Clear sprites
	lda #$ff
	ldx #0
clearsprites:
	sta sprites, x
	inx
	bne clearsprites

	; Add sprite for current location
	lda cur_screen_y
	asl
	asl
	asl
	clc
	adc #23
	sta sprites
	lda #MINIMAP_TILE_INDICATORS
	sta sprites + 1
	lda #1
	sta sprites + 2
	lda cur_screen_x
	asl
	asl
	asl
	clc
	adc #24
	sta sprites + 3

	LOAD_PTR minimap_palette
	jsr fade_in

	lda #0
	sta selection

waitfordepress:
	jsr wait_for_vblank
	jsr update_minimap_palette & $ffff

	jsr update_controller
	lda controller
	bne waitfordepress

selectloop:
	jsr wait_for_vblank
	jsr update_minimap_palette & $ffff

	jsr update_controller
	lda controller
	and #JOY_START
	beq notstart
	jmp done & $ffff

notstart:
	lda controller
	and #JOY_LEFT | JOY_RIGHT | JOY_SELECT
	beq selectloop

	lda selection
	eor #1
	sta selection
	beq selectresume

	jsr wait_for_vblank
	jsr update_minimap_palette & $ffff

	LOAD_PTR minimap_clear
	ldx #1
	ldy #32 + 26
	lda #1
	jsr write_tiles
	LOAD_PTR minimap_clear
	ldx #10
	ldy #32 + 26
	lda #1
	jsr write_tiles
	LOAD_PTR minimap_right_arrow
	ldx #12
	ldy #32 + 26
	lda #1
	jsr write_tiles
	LOAD_PTR minimap_left_arrow
	ldx #28
	ldy #32 + 26
	lda #1
	jsr write_tiles
	LOAD_PTR minimap_deselected_palette
	lda #1
	jsr load_single_palette
	LOAD_PTR minimap_selected_palette
	lda #2
	jsr load_single_palette
	jsr prepare_for_rendering
	jmp waitfordepress & $ffff

selectresume:
	jsr wait_for_vblank
	jsr update_minimap_palette & $ffff

	LOAD_PTR minimap_right_arrow
	ldx #1
	ldy #32 + 26
	lda #1
	jsr write_tiles
	LOAD_PTR minimap_left_arrow
	ldx #10
	ldy #32 + 26
	lda #1
	jsr write_tiles
	LOAD_PTR minimap_clear
	ldx #12
	ldy #32 + 26
	lda #1
	jsr write_tiles
	LOAD_PTR minimap_clear
	ldx #28
	ldy #32 + 26
	lda #1
	jsr write_tiles
	LOAD_PTR minimap_selected_palette
	lda #1
	jsr load_single_palette
	LOAD_PTR minimap_deselected_palette
	lda #2
	jsr load_single_palette
	jsr prepare_for_rendering
	jmp waitfordepress & $ffff

done:
	jsr wait_for_vblank
	jsr update_minimap_palette & $ffff

	jsr update_controller
	lda controller
	bne done

	jsr fade_out

	lda saved_ppu_settings
	sta ppu_settings

	lda selection
	cmp #1
	beq quit

	jsr back_to_game_from_minimap

	LOAD_PTR saved_palette
	jsr fade_in

	lda #0
	rts

quit:
	jsr save
	jmp start
.endproc


PROC update_minimap_palette
	lda vblank_count
	and #15
	cmp #8
	bcs white

	lda #2
	sta sprites + 2
	jmp done & $ffff

white:
	lda #1
	sta sprites + 2

done:
	rts
.endproc


.segment "FIXED"

PROC set_ppu_addr_to_minimap_tile
	txa
	clc
	adc #2
	tax
	tya
	clc
	adc #32 + 2
	tay
	jsr set_ppu_addr_to_coord
	rts
.endproc


PROC write_minimap_tile
	pha
	jsr set_ppu_addr_to_minimap_tile
	pla
	sta PPUDATA
	rts
.endproc


PROC get_minimap_tile_for_type
	cmp #MAP_CAVE_START
	beq rock
	cmp #MAP_BOUNDARY
	beq rock
	cmp #MAP_CAVE_INTERIOR
	beq rock
	cmp #MAP_BLOCKY_TREASURE
	beq rock
	cmp #MAP_BLOCKY_PUZZLE
	beq rock
	cmp #MAP_BLOCKY_CAVE
	beq rock
	cmp #MAP_STARTING_CAVE
	beq rock
	cmp #MAP_LOST_CAVE
	beq rock
	cmp #MAP_MINE_ENTRANCE
	beq rock
	cmp #MAP_MINE_DOWN
	beq rock

	cmp #MAP_FOREST
	beq forest
	cmp #MAP_DEAD_WOOD
	beq forest
	cmp #MAP_UNBEARABLE
	beq forest
	cmp #MAP_START_FOREST
	beq forest

	cmp #MAP_HOUSE
	beq house
	cmp #MAP_SHOP
	beq shop
	cmp #MAP_PARK
	beq park

	cmp #MAP_LAKE
	beq lake

	cmp #MAP_BOSS
	beq base
	cmp #MAP_BASE_HORDE
	beq base
	cmp #MAP_BASE_INTERIOR
	beq base

rock:
	lda #MINIMAP_TILE_ROCK + SMALL_BORDER_CENTER
	rts

forest:
	ldx arg0
	ldy arg1
	lda arg0
	jsr gen8

	and #3
	beq park

	lda #MINIMAP_TILE_FOREST
	rts

house:
	lda #MINIMAP_TILE_TOWN
	rts

shop:
	lda #MINIMAP_TILE_TOWN + 1
	rts

park:
	lda #MINIMAP_TILE_FOREST + 1
	rts

lake:
	lda #MINIMAP_TILE_LAKE + SMALL_BORDER_CENTER
	rts

base:
	lda #MINIMAP_TILE_BASE + SMALL_BORDER_CENTER
	rts
.endproc


.data
VAR minimap_top_row
	.byte 0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,0
VAR minimap_mid_row
	.byte 0,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,6,0
VAR minimap_bot_row
	.byte 0,7,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,9,0

VAR resume_str
	.byte "RESUME", 0
VAR save_str
	.byte "SAVE", 0
VAR and_str
	.byte "AND", 0
VAR quit_str
	.byte "QUIT", 0

VAR minimap_left_arrow
	.byte MINIMAP_TILE_ARROWS
VAR minimap_right_arrow
	.byte MINIMAP_TILE_ARROWS + 1
VAR minimap_clear
	.byte 0

VAR minimap_palette
	.byte $0f, $0f, $16, $37
	.byte $0f, $21, $21, $21
	.byte $0f, $30, $30, $30
	.byte $0f, $0f, $27, $37
	.byte $0f, $0f, $16, $37
	.byte $0f, $0f, $30, $30
	.byte $0f, $0f, $21, $21
	.byte $0f, $0f, $16, $37

VAR minimap_selected_palette
	.byte $0f, $21, $21, $21
VAR minimap_deselected_palette
	.byte $0f, $30, $30, $30


.segment "TEMP"
VAR saved_ppu_settings
	.byte 0

VAR saved_palette
	.byte 0, 0, 0, 0
	.byte 0, 0, 0, 0
	.byte 0, 0, 0, 0
	.byte 0, 0, 0, 0
	.byte 0, 0, 0, 0
	.byte 0, 0, 0, 0
	.byte 0, 0, 0, 0
	.byte 0, 0, 0, 0


TILES minimap_background_tiles, 2, "tiles/map/background.chr", 9
TILES minimap_forest_tiles, 2, "tiles/map/forest.chr", 2
TILES minimap_cave_entrace_tile, 2, "tiles/map/cave.chr", 1
TILES minimap_rock_tiles, 2, "tiles/map/rock.chr", 33
TILES minimap_lake_tiles, 2, "tiles/map/lake.chr", 33
TILES minimap_town_tiles, 2, "tiles/map/town.chr", 2
TILES minimap_base_tiles, 2, "tiles/map/base.chr", 15
TILES minimap_arrow_tiles, 2, "tiles/map/arrows.chr", 2
TILES minimap_indicator_tiles, 2, "tiles/map/indicators.chr", 2
