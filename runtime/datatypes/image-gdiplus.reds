Red/System [
	Title:   "Image routine functions using GDI+"
	Author:  "Qingtian Xie"
	File: 	 %image-gdiplus.red
	Type:	 'library
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#enum ImageLockMode! [
    ImageLockModeRead:			1
    ImageLockModeWrite:			2
    ImageLockModeUserInputBuf:	4
]

;-- In-memory pixel data formats:
;-- bits 0-7 = format index
;-- bits 8-15 = pixel size (in bits)
;-- bits 16-23 = flags
;-- bits 24-31 = reserved

#define    PixelFormatIndexed         00010000h ;-- Indexes into a palette
#define    PixelFormatGDI             00020000h ;-- Is a GDI-supported format
#define    PixelFormatAlpha           00040000h ;-- Has an alpha component
#define    PixelFormatPAlpha          00080000h ;-- Pre-multiplied alpha
#define    PixelFormatExtended        00100000h ;-- Extended color 16 bits/channel
#define    PixelFormatCanonical       00200000h

#define    PixelFormatUndefined       0
#define    PixelFormatDontCare        0

#define    PixelFormat32bppARGB       [10 or (32 << 8) or PixelFormatAlpha or PixelFormatGDI or PixelFormatCanonical]
#define    PixelFormat32bppPARGB      [11 or (32 << 8) or PixelFormatAlpha or PixelFormatPAlpha or PixelFormatGDI]
#define    PixelFormat32bppCMYK       [15 or (32 << 8)]
#define    PixelFormatMax             16

;-- PixelFormat
#define GL_COLOR_INDEX                    1900h
#define GL_STENCIL_INDEX                  1901h
#define GL_DEPTH_COMPONENT                1902h
#define GL_RED                            1903h
#define GL_GREEN                          1904h
#define GL_BLUE                           1905h
#define GL_ALPHA                          1906h
#define GL_RGB                            1907h
#define GL_RGBA                           1908h
#define GL_LUMINANCE                      1909h
#define GL_LUMINANCE_ALPHA                190Ah

#define GpBitmap!	int-ptr!
#define GpImage!	int-ptr!
#define GpGraphics! int-ptr!

RECT!: alias struct! [
	left	[integer!]
	top		[integer!]
	right	[integer!]
	bottom	[integer!]
]

BitmapData!: alias struct! [
	width		[integer!]
	height		[integer!]
	stride		[integer!]
	pixelFormat	[integer!]
	scan0		[byte-ptr!]
	reserved	[integer!]
]

#import [
	"kernel32.dll" stdcall [
		GlobalAlloc: "GlobalAlloc" [
			flags		[integer!]
			size		[integer!]
			return:		[int-ptr!]
		]
		GlobalFree: "GlobalFree" [
			hMem		[integer!]
			return:		[integer!]
		]
		GlobalLock: "GlobalLock" [
			hMem		[integer!]
			return:		[integer!]
		]
	]
	"ole32.dll" stdcall [
		CreateStreamOnHGlobal: "CreateStreamOnHGlobal" [
			hMem		[integer!]
			fAutoDel	[logic!]
			ppstm		[int-ptr!]
			return:		[integer!]
		]
	]
	"gdiplus.dll" stdcall [
		GdipCreateBitmapFromFile: "GdipCreateBitmapFromFile" [
			filename	[c-string!]
			image		[GpBitmap!]
			return:		[integer!]
		]
		GdipBitmapLockBits: "GdipBitmapLockBits" [
			bitmap		[integer!]
			rect		[RECT!]
			flags		[integer!]
			format		[integer!]
			data		[BitmapData!]
			return:		[integer!]
		]
		GdipBitmapUnlockBits: "GdipBitmapUnlockBits" [
			bitmap		[integer!]
			data		[BitmapData!]
			return:		[integer!]
		]
		GdipGetImageWidth: "GdipGetImageWidth" [
			image		[integer!]
			width		[int-ptr!]
			return:		[integer!]
		]
		GdipGetImageHeight: "GdipGetImageHeight" [
			image		[integer!]
			height		[int-ptr!]
			return:		[integer!]
		]
	]
]

width?: func [
	handle		[integer!]
	return:		[integer!]
	/local
		width	[integer!]
][
	width: 0
	GdipGetImageWidth handle :width
	width
]

height?: func [
	handle		[integer!]
	return:		[integer!]
	/local
		height	[integer!]
][
	height: 0
	GdipGetImageHeight handle :height
	height
]

get-data: func [
	handle		[integer!]
	return:		[int-ptr!]
	/local
		rect	[RECT!]
		data	[BitmapData!]
][
	rect: declare RECT!
	data: as BitmapData! allocate size? BitmapData!
	rect/left: 0
	rect/top: 0
	rect/right: width? handle
	rect/bottom: height? handle
	GdipBitmapLockBits handle rect ImageLockModeWrite PixelFormat32bppPARGB data
	as int-ptr! data
]

update-data: func [
	handle		[integer!]
	data		[int-ptr!]
][
	GdipBitmapUnlockBits handle as BitmapData! data
	free as byte-ptr! data
]

get-pixel: func [
	data		[int-ptr!]
	x			[integer!]
	y			[integer!]
	return:		[integer!]
	/local
		bitmap	[BitmapData!]
		buf		[int-ptr!]
		pos		[integer!]
][
	bitmap: as BitmapData! data
	pos: y * bitmap/stride + x
	buf: as int-ptr! bitmap/scan0
	buf/pos
]

load-image: func [
	filename	[c-string!]				;-- UTF-16 string
	return:		[integer!]
	/local
		handle	[integer!]
		res		[integer!]
][
	handle: 0
	res: GdipCreateBitmapFromFile filename :handle
	unless zero? res [platform/error-msg res]
	handle
]