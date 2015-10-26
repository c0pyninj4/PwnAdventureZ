.include "defines.inc"

.define FOREST_TILES    $80
.define SHOP_WALL_TILES $88
.define SHOP_SIGN_TILES $a8
.define HOUSE_EXT_TILES $b0

.define HOUSE_ROOF_PALETTE  1
.define HOUSE_FRONT_PALETTE 2


.segment "FIXED"

PROC gen_shop
	lda inside
	beq outside

	lda current_bank
	pha
	lda #^do_gen_shop_inside
	jsr bankswitch
	jsr do_gen_shop_inside & $ffff
	pla
	jsr bankswitch
	rts

outside:
	lda current_bank
	pha
	lda #^do_gen_shop_outside
	jsr bankswitch
	jsr do_gen_shop_outside & $ffff
	pla
	jsr bankswitch
	rts
.endproc


.segment "EXTRA"

PROC do_gen_shop_outside
	; Load forest tiles
	LOAD_ALL_TILES FOREST_TILES, forest_tiles
	LOAD_ALL_TILES SHOP_WALL_TILES, shop_wall_tiles
	LOAD_ALL_TILES SHOP_SIGN_TILES, shop_sign_tiles
	LOAD_ALL_TILES HOUSE_EXT_TILES, house_exterior_tiles

	; Set up collision and spawning info
	lda #FOREST_TILES + FOREST_GRASS
	sta traversable_tiles
	lda #HOUSE_EXT_TILES + 36
	sta traversable_tiles + 1
	lda #HOUSE_EXT_TILES + 28
	sta traversable_tiles + 2
	lda #HOUSE_EXT_TILES + 40
	sta traversable_tiles + 3
	lda #FOREST_TILES + FOREST_GRASS
	sta spawnable_tiles
	lda #HOUSE_EXT_TILES + 28
	sta spawnable_tiles + 1
	lda #HOUSE_EXT_TILES + 40
	sta spawnable_tiles + 2

	; Load palette
	LOAD_PTR shop_exterior_palette
	jsr load_background_game_palette

	; Generate parameters for map generation
	jsr gen_map_opening_locations

	lda #FOREST_TILES + FOREST_TREE
	jsr gen_left_wall_small
	lda #FOREST_TILES + FOREST_TREE
	jsr gen_right_wall_small
	lda #FOREST_TILES + FOREST_TREE
	jsr gen_top_wall_single
	lda #FOREST_TILES + FOREST_TREE
	jsr gen_bot_wall_small

	lda #FOREST_TILES + FOREST_GRASS
	jsr gen_walkable_path

	; Generate wall around shop
	ldx #3
	ldy #2
	lda #SHOP_WALL_TILES + 0
	jsr write_gen_map
	lda #SHOP_WALL_TILES + 24
	ldx #4
topwall:
	jsr write_gen_map
	inx
	cpx #11
	bne topwall
	lda #SHOP_WALL_TILES + 4
	jsr write_gen_map

	ldy #3
	lda #SHOP_WALL_TILES + 8
centerwall:
	ldx #3
	jsr write_gen_map
	ldx #11
	jsr write_gen_map
	iny
	cpy #8
	bne centerwall

	lda #5
	jsr genrange_cur
	clc
	adc #5
	sta arg0

	ldx #3
	ldy #8
	lda #SHOP_WALL_TILES + 12
	jsr write_gen_map
	lda #SHOP_WALL_TILES + 24
	ldx #4
botwallleft:
	jsr write_gen_map
	inx
	cpx arg0
	bne botwallleft

	dex
	lda #SHOP_WALL_TILES + 28
	jsr write_gen_map
	inx
	lda #FOREST_TILES + FOREST_GRASS
	jsr write_gen_map
	inx
	lda #SHOP_WALL_TILES + 20
	jsr write_gen_map

	inx
	lda #SHOP_WALL_TILES + 24
botwallright:
	cpx #11
	beq botwalldone
	jsr write_gen_map
	inx
	jmp botwallright & $ffff
botwalldone:
	lda #SHOP_WALL_TILES + 16
	jsr write_gen_map

	ldx #5
	ldy #4
	lda #HOUSE_EXT_TILES + 12 + HOUSE_ROOF_PALETTE
	jsr write_gen_map
	inx
	lda #HOUSE_EXT_TILES + 0 + HOUSE_ROOF_PALETTE
	jsr write_gen_map
	inx
	lda #HOUSE_EXT_TILES + 4 + HOUSE_ROOF_PALETTE
	jsr write_gen_map
	inx
	lda #HOUSE_EXT_TILES + 8 + HOUSE_ROOF_PALETTE
	jsr write_gen_map
	inx
	lda #HOUSE_EXT_TILES + 12 + HOUSE_ROOF_PALETTE
	jsr write_gen_map
	inx
	lda #HOUSE_EXT_TILES + 28
	jsr write_gen_map

	ldx #5
	iny
	lda #HOUSE_EXT_TILES + 12 + HOUSE_ROOF_PALETTE
	jsr write_gen_map
	inx
	lda #HOUSE_EXT_TILES + 16 + HOUSE_ROOF_PALETTE
	jsr write_gen_map
	inx
	lda #HOUSE_EXT_TILES + 20 + HOUSE_ROOF_PALETTE
	jsr write_gen_map
	inx
	lda #HOUSE_EXT_TILES + 24 + HOUSE_ROOF_PALETTE
	jsr write_gen_map
	inx
	lda #HOUSE_EXT_TILES + 12 + HOUSE_ROOF_PALETTE
	jsr write_gen_map
	inx
	lda #HOUSE_EXT_TILES + 28
	jsr write_gen_map

	ldx #5
	iny
	lda #HOUSE_EXT_TILES + 32 + HOUSE_FRONT_PALETTE
	jsr write_gen_map
	inx
	lda #SHOP_SIGN_TILES + 0 + HOUSE_FRONT_PALETTE
	jsr write_gen_map
	inx
	lda #HOUSE_EXT_TILES + 36 + HOUSE_FRONT_PALETTE
	jsr write_gen_map
	inx
	lda #SHOP_SIGN_TILES + 4 + HOUSE_FRONT_PALETTE
	jsr write_gen_map
	inx
	lda #HOUSE_EXT_TILES + 32 + HOUSE_FRONT_PALETTE
	jsr write_gen_map
	inx
	lda #HOUSE_EXT_TILES + 40
	jsr write_gen_map

	lda #7
	sta entrance_x
	lda #6
	sta entrance_y

	; Pick house paint color
	lda #3
	jsr genrange_cur
	tay
	lda house_paint_colors & $ffff, y
	sta scratch + 3
	sta scratch + 7

	; Pick house roof color
	lda #3
	jsr genrange_cur
	tay
	lda roof_dark_colors & $ffff, y
	sta scratch + 1
	lda roof_light_colors & $ffff, y
	sta scratch + 2

	; Complete and load house palettes
	lda #$0f
	sta scratch
	sta scratch + 4
	lda #$01
	sta scratch + 5
	lda #$17
	sta scratch + 6

	LOAD_PTR scratch
	jsr load_game_palette_1
	LOAD_PTR scratch + 4
	jsr load_game_palette_2

	; Convert tiles that have not been generated into grass
	ldy #0
yloop:
	ldx #0
xloop:
	jsr read_gen_map
	cmp #0
	bne nextblank
	lda #FOREST_TILES + FOREST_GRASS
	jsr write_gen_map
nextblank:
	inx
	cpx #MAP_WIDTH
	bne xloop
	iny
	cpy #MAP_HEIGHT
	bne yloop
	rts
.endproc


PROC do_gen_shop_inside
	jsr gen_house_inside_common & $ffff
	rts
.endproc


VAR shop_exterior_palette
	.byte $0f, $09, $19, $00
	.byte $0f, $09, $19, $00
	.byte $0f, $09, $19, $00
	.byte $0f, $09, $19, $00


TILES shop_wall_tiles, 3, "tiles/house/shopwall.chr", 32
TILES shop_sign_tiles, 3, "tiles/house/shopsign.chr", 8
