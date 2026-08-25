/***************************************************************************
    copyright            : (C) 2003 by Scott Wheeler
    email                : wheeler@kde.org
 ***************************************************************************/

/***************************************************************************
 *   This library is free software; you can redistribute it and/or modify  *
 *   it  under the terms of the GNU Lesser General Public License version  *
 *   2.1 as published by the Free Software Foundation.                     *
 *                                                                         *
 *   This library is distributed in the hope that it will be useful, but   *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   Lesser General Public License for more details.                       *
 *                                                                         *
 *   You should have received a copy of the GNU Lesser General Public      *
 *   License along with this library; if not, write to the Free Software   *
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  *
 *   USA                                                                   *
 ***************************************************************************/
package taglib

foreign import lib "system:tag_c"
_ :: lib

/*
* These are used to give the C API some type safety (as opposed to
* using void * ), but pointers to them are simply cast to the corresponding C++
* types in the implementation.
*/
TagLib_File :: struct {
	/*******************************************************************************
	* [ TagLib C Binding ]
	*
	* This is an interface to TagLib's "simple" API, meaning that you can read and
	* modify media files in a generic, but not specialized way.  This is a rough
	* representation of TagLib::File and TagLib::Tag, for which the documentation
	* is somewhat more complete and worth consulting.
	*******************************************************************************/

	/*
	* These are used to give the C API some type safety (as opposed to
	* using void * ), but pointers to them are simply cast to the corresponding C++
	* types in the implementation.
	*/
	dummy: i32,
}

TagLib_Tag :: struct {
	dummy: i32,
}

TagLib_AudioProperties :: struct {
	dummy: i32,
}

TagLib_IOStream :: struct {
	dummy: i32,
}

@(default_calling_convention = "c", link_prefix = "taglib_")
foreign lib {
	/*!
	* By default all strings coming into or out of TagLib's C API are in UTF8.
	* However, it may be desirable for TagLib to operate on Latin1 (ISO-8859-1)
	* strings in which case this should be set to FALSE.
	*/
	set_strings_unicode :: proc(unicode: i32) ---

	/*!
	* TagLib can keep track of strings that are created when outputting tag values
	* and clear them using taglib_tag_clear_strings().  This is enabled by default.
	* However if you wish to do more fine grained management of strings, you can do
	* so by setting \a management to FALSE.
	*/
	set_string_management_enabled :: proc(management: i32) ---

	/*!
	* Explicitly free a string returned from TagLib
	*/
	free :: proc(pointer: rawptr) ---

	/*!
	* Creates a byte vector stream from \a size bytes of \a data.
	* Such a stream can be used with taglib_file_new_iostream() to create a file
	* from memory.
	*/
	memory_iostream_new :: proc(data: cstring, size: u32) -> ^TagLib_IOStream ---

	/*!
	* Frees and closes the stream.
	*/
	iostream_free :: proc(stream: ^TagLib_IOStream) ---
}

/*******************************************************************************
* File API
******************************************************************************/
TagLib_File_Type :: enum u32 {
	MPEG      = 0,
	OggVorbis = 1,
	FLAC      = 2,
	MPC       = 3,
	OggFlac   = 4,
	WavPack   = 5,
	Speex     = 6,
	TrueAudio = 7,
	MP4       = 8,
	ASF       = 9,
	AIFF      = 10,
	WAV       = 11,
	APE       = 12,
	IT        = 13,
	Mod       = 14,
	S3M       = 15,
	XM        = 16,
	Opus      = 17,
	DSF       = 18,
	DSDIFF    = 19,
	SHORTEN   = 20,
	MATROSKA  = 21,
}

@(default_calling_convention = "c", link_prefix = "taglib_")
foreign lib {
	/*!
	* Creates a TagLib file based on \a filename.  TagLib will try to guess the file
	* type.
	*
	* \returns NULL if the file type cannot be determined or the file cannot
	* be opened.
	*/
	file_new :: proc(filename: cstring) -> ^TagLib_File ---

	/*!
	* Creates a TagLib file based on \a filename.  Rather than attempting to guess
	* the type, it will use the one specified by \a type.
	*/
	file_new_type :: proc(filename: cstring, type: TagLib_File_Type) -> ^TagLib_File ---

	/*!
	* Creates a TagLib file from a \a stream.
	* A byte vector stream can be used to read a file from memory and write to
	* memory, e.g. when fetching network data.
	* The stream has to be created using taglib_memory_iostream_new() and shall be
	* freed using taglib_iostream_free() \e after this file is freed with
	* taglib_file_free().
	*/
	file_new_iostream :: proc(stream: ^TagLib_IOStream) -> ^TagLib_File ---

	/*!
	* Frees and closes the file.
	*/
	file_free :: proc(file: ^TagLib_File) ---

	/*!
	* Returns \c true if the file is open and readable and valid information for
	* the Tag and / or AudioProperties was found.
	*/
	file_is_valid :: proc(file: ^TagLib_File) -> i32 ---

	/*!
	* Returns a pointer to the tag associated with this file.  This will be freed
	* automatically when the file is freed.
	*/
	file_tag :: proc(file: ^TagLib_File) -> ^TagLib_Tag ---

	/*!
	* Returns a pointer to the audio properties associated with this file.  This
	* will be freed automatically when the file is freed.
	*/
	file_audioproperties :: proc(file: ^TagLib_File) -> ^TagLib_AudioProperties ---

	/*!
	* Saves the \a file to disk.
	*/
	file_save :: proc(file: ^TagLib_File) -> i32 ---

	/*!
	* Returns a string with this tag's title.
	*
	* \note By default this string should be UTF8 encoded and its memory should be
	* freed using taglib_tag_free_strings().
	*/
	tag_title :: proc(tag: ^TagLib_Tag) -> cstring ---

	/*!
	* Returns a string with this tag's artist.
	*
	* \note By default this string should be UTF8 encoded and its memory should be
	* freed using taglib_tag_free_strings().
	*/
	tag_artist :: proc(tag: ^TagLib_Tag) -> cstring ---

	/*!
	* Returns a string with this tag's album name.
	*
	* \note By default this string should be UTF8 encoded and its memory should be
	* freed using taglib_tag_free_strings().
	*/
	tag_album :: proc(tag: ^TagLib_Tag) -> cstring ---

	/*!
	* Returns a string with this tag's comment.
	*
	* \note By default this string should be UTF8 encoded and its memory should be
	* freed using taglib_tag_free_strings().
	*/
	tag_comment :: proc(tag: ^TagLib_Tag) -> cstring ---

	/*!
	* Returns a string with this tag's genre.
	*
	* \note By default this string should be UTF8 encoded and its memory should be
	* freed using taglib_tag_free_strings().
	*/
	tag_genre :: proc(tag: ^TagLib_Tag) -> cstring ---

	/*!
	* Returns the tag's year or 0 if the year is not set.
	*/
	tag_year :: proc(tag: ^TagLib_Tag) -> u32 ---

	/*!
	* Returns the tag's track number or 0 if the track number is not set.
	*/
	tag_track :: proc(tag: ^TagLib_Tag) -> u32 ---

	/*!
	* Sets the tag's title.
	*
	* \note By default this string should be UTF8 encoded.
	*/
	tag_set_title :: proc(tag: ^TagLib_Tag, title: cstring) ---

	/*!
	* Sets the tag's artist.
	*
	* \note By default this string should be UTF8 encoded.
	*/
	tag_set_artist :: proc(tag: ^TagLib_Tag, artist: cstring) ---

	/*!
	* Sets the tag's album.
	*
	* \note By default this string should be UTF8 encoded.
	*/
	tag_set_album :: proc(tag: ^TagLib_Tag, album: cstring) ---

	/*!
	* Sets the tag's comment.
	*
	* \note By default this string should be UTF8 encoded.
	*/
	tag_set_comment :: proc(tag: ^TagLib_Tag, comment: cstring) ---

	/*!
	* Sets the tag's genre.
	*
	* \note By default this string should be UTF8 encoded.
	*/
	tag_set_genre :: proc(tag: ^TagLib_Tag, genre: cstring) ---

	/*!
	* Sets the tag's year.  0 indicates that this field should be cleared.
	*/
	tag_set_year :: proc(tag: ^TagLib_Tag, year: u32) ---

	/*!
	* Sets the tag's track number.  0 indicates that this field should be cleared.
	*/
	tag_set_track :: proc(tag: ^TagLib_Tag, track: u32) ---

	/*!
	* Frees all of the strings that have been created by the tag.
	*/
	tag_free_strings :: proc() ---

	/*!
	* Returns the length of the file in seconds.
	*/
	audioproperties_length :: proc(audioProperties: ^TagLib_AudioProperties) -> i32 ---

	/*!
	* Returns the bitrate of the file in kb/s.
	*/
	audioproperties_bitrate :: proc(audioProperties: ^TagLib_AudioProperties) -> i32 ---

	/*!
	* Returns the sample rate of the file in Hz.
	*/
	audioproperties_samplerate :: proc(audioProperties: ^TagLib_AudioProperties) -> i32 ---

	/*!
	* Returns the number of channels in the audio stream.
	*/
	audioproperties_channels :: proc(audioProperties: ^TagLib_AudioProperties) -> i32 ---
}

/*******************************************************************************
* Special convenience ID3v2 functions
*******************************************************************************/
TagLib_ID3v2_Encoding :: enum u32 {
	Latin1  = 0,
	UTF16   = 1,
	UTF16BE = 2,
	UTF8    = 3,
}

@(default_calling_convention = "c", link_prefix = "taglib_")
foreign lib {
	/*!
	* This sets the default encoding for ID3v2 frames that are written to tags.
	*/
	id3v2_set_default_text_encoding :: proc(encoding: TagLib_ID3v2_Encoding) ---

	/*!
	* Sets the property \a prop with \a value.  Use \a value = NULL to remove
	* the property, otherwise it will be replaced.
	*/
	property_set :: proc(file: ^TagLib_File, prop: cstring, value: cstring) ---

	/*!
	* Appends \a value to the property \a prop (sets it if non-existing).
	* Use \a value = NULL to remove all values associated with the property.
	*/
	property_set_append :: proc(file: ^TagLib_File, prop: cstring, value: cstring) ---

	/*!
	* Get the keys of the property map.
	*
	* \return NULL terminated array of C-strings (char *), only NULL if empty.
	* It must be freed by the client using taglib_property_free().
	*/
	property_keys :: proc(file: ^TagLib_File) -> ^cstring ---

	/*!
	* Get value(s) of property \a prop.
	*
	* \return NULL terminated array of C-strings (char *), only NULL if empty.
	* It must be freed by the client using taglib_property_free().
	*/
	property_get :: proc(file: ^TagLib_File, prop: cstring) -> ^cstring ---

	/*!
	* Frees the NULL terminated array \a props and the C-strings it contains.
	*/
	property_free :: proc(props: ^cstring) ---
}

/*!
* Types which can be stored in a TagLib_Variant.
*
* \related TagLib::Variant::Type
* These correspond to TagLib::Variant::Type, but ByteVectorList, VariantList,
* VariantMap are not supported and will be returned as their string
* representation.
*/
TagLib_Variant_Type :: enum u32 {
	Void       = 0,
	Bool       = 1,
	Int        = 2,
	UInt       = 3,
	LongLong   = 4,
	ULongLong  = 5,
	Double     = 6,
	String     = 7,
	StringList = 8,
	ByteVector = 9,
}

/*!
* Discriminated union used in complex property attributes.
*
* \e type must be set according to the \e value union used.
* \e size is only required for TagLib_Variant_ByteVector and must contain
* the number of bytes.
*
* \related TagLib::Variant.
*/
TagLib_Variant :: struct {
	type:  TagLib_Variant_Type,
	size:  u32,
	value: struct #raw_union {
		stringValue:     cstring,
		byteVectorValue: cstring,
		stringListValue: ^cstring,
		boolValue:       i32,
		intValue:        i32,
		uIntValue:       u32,
		longLongValue:   i64,
		uLongLongValue:  u64,
		doubleValue:     f64,
	},
}

/*!
* Attribute of a complex property.
* Complex properties consist of a NULL-terminated array of pointers to
* this structure with \e key and \e value.
*/
TagLib_Complex_Property_Attribute :: struct {
	key:   cstring,
	value: TagLib_Variant,
}

/*!
* Picture data extracted from a complex property by the convenience function
* taglib_picture_from_complex_property().
*/
TagLib_Complex_Property_Picture_Data :: struct {
	mimeType:    cstring,
	description: cstring,
	pictureType: cstring,
	data:        cstring,
	size:        u32,
}

@(default_calling_convention = "c", link_prefix = "taglib_")
foreign lib {
	/*!
	* Sets the complex property \a key with \a value.  Use \a value = NULL to
	* remove the property, otherwise it will be replaced with the NULL
	* terminated array of attributes in \a value.
	*
	* A picture can be set with the TAGLIB_COMPLEX_PROPERTY_PICTURE macro:
	*
	* \code {.c}
	* TagLib_File *file = taglib_file_new("myfile.mp3");
	* FILE *fh = fopen("mypicture.jpg", "rb");
	* if(fh) {
	*   fseek(fh, 0L, SEEK_END);
	*   long size = ftell(fh);
	*   fseek(fh, 0L, SEEK_SET);
	*   char *data = (char *)malloc(size);
	*   fread(data, size, 1, fh);
	*   TAGLIB_COMPLEX_PROPERTY_PICTURE(props, data, size, "Written by TagLib",
	*                                   "image/jpeg", "Front Cover");
	*   taglib_complex_property_set(file, "PICTURE", props);
	*   taglib_file_save(file);
	*   free(data);
	*   fclose(fh);
	* }
	* \endcode
	*/
	complex_property_set :: proc(file: ^TagLib_File, key: cstring, value: ^^TagLib_Complex_Property_Attribute) -> i32 ---

	/*!
	* Appends \a value to the complex property \a key (sets it if non-existing).
	* Use \a value = NULL to remove all values associated with the \a key.
	*/
	complex_property_set_append :: proc(file: ^TagLib_File, key: cstring, value: ^^TagLib_Complex_Property_Attribute) -> i32 ---

	/*!
	* Get the keys of the complex properties.
	*
	* \return NULL terminated array of C-strings (char *), only NULL if empty.
	* It must be freed by the client using taglib_complex_property_free_keys().
	*/
	complex_property_keys :: proc(file: ^TagLib_File) -> ^cstring ---

	/*!
	* Get value(s) of complex property \a key.
	*
	* \return NULL terminated array of property values, which are themselves an
	* array of property attributes, only NULL if empty.
	* It must be freed by the client using taglib_complex_property_free().
	*/
	complex_property_get :: proc(file: ^TagLib_File, key: cstring) -> ^^^TagLib_Complex_Property_Attribute ---

	/*!
	* Extract the complex property values of a picture.
	*
	* This function can be used to get the data from a "PICTURE" complex property
	* without having to traverse the whole variant map. A picture can be
	* retrieved like this:
	*
	* \code {.c}
	* TagLib_File *file = taglib_file_new("myfile.mp3");
	* TagLib_Complex_Property_Attribute*** properties =
	*   taglib_complex_property_get(file, "PICTURE");
	* TagLib_Complex_Property_Picture_Data picture;
	* taglib_picture_from_complex_property(properties, &picture);
	* // Do something with picture.mimeType, picture.description,
	* // picture.pictureType, picture.data, picture.size, e.g. extract it.
	* FILE *fh = fopen("mypicture.jpg", "wb");
	* if(fh) {
	*   fwrite(picture.data, picture.size, 1, fh);
	*   fclose(fh);
	* }
	* taglib_complex_property_free(properties);
	* \endcode
	*
	* Note that the data in \a picture contains pointers to data in \a properties,
	* i.e. it only lives as long as the properties, until they are freed with
	* taglib_complex_property_free().
	* If you want to access multiple pictures or additional properties of FLAC
	* pictures ("width", "height", "numColors", "colorDepth" int values), you
	* have to traverse the \a properties yourself.
	*/
	picture_from_complex_property :: proc(properties: ^^^TagLib_Complex_Property_Attribute, picture: ^TagLib_Complex_Property_Picture_Data) ---

	/*!
	* Frees the NULL terminated array \a keys (as returned by
	* taglib_complex_property_keys()) and the C-strings it contains.
	*/
	complex_property_free_keys :: proc(keys: ^cstring) ---

	/*!
	* Frees the NULL terminated array \a props of property attribute arrays
	* (as returned by taglib_complex_property_get()) and the data such as
	* C-strings and byte vectors contained in these attributes.
	*/
	complex_property_free :: proc(props: ^^^TagLib_Complex_Property_Attribute) ---
}
