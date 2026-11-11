*------------------------------------------------------------------------------*
PROCEDURE ViewCode
*------------------------------------------------------------------------------*
Local Code

	if ! IsWindowDefined(&DesignForm)
		MsgStop ( aMsgs [ 086 ] ,'HMG IDE')
		RETURN
	EndIf

	Code := Save ( .T. )

	define window ViewCode ;
		at 0,0 ;
		width 640 ;
		height 480 ;
		title 'Form Code' ;
		Modal ;
		NoSize

		define editbox edit_1
			row 0
			col 0
			width 635
			height 480 - GetTitleHeight() - GetBorderHeight() - 2
			Value Code
			fontname 'Courier New'
			fontsize 10
			ReadOnly .T.
		end editbox

	end window

	ViewCode.Center

	activate window ViewCode

	DoMethod ( DesignForm , 'SetFocus' )
	DrawGrid()

RETURN

*------------------------------------------------------------------------------*
FUNCTION PickPropertyValue ( Title , Legend , Options , CurrentValue )
*------------------------------------------------------------------------------*
Local RetVal 
Local i
Local InitValue := 0

        For i := 1 To HMG_LEN ( Options )
		If	ALLTRIM ( HMG_UPPER ( Options [i] ) ) ; 
			== ;
			ALLTRIM ( HMG_UPPER ( CurrentValue ) ) ; 

				InitValue := i
				Exit

		EndIf
	Next i

	Define Window PickPropertyValue ;
		At 0,0 ;
		Width 300 ;
		Height GetTitleHeight() + 115 + 2 ;
		Title Title ;
		Modal ;
		NoSize ;
		NoSysMenu

		ON KEY RETURN	Action	( ;
				RetVal := PickPropertyValue.PickValue.Item( PickPropertyValue.PickValue.Value ) , ;
				_HMG_SYSDATA [ 257 ] := .F. , ;
				PickPropertyValue.Release ;
				) 

		ON KEY ESCAPE	Action	( ;
				RetVal := '' , ;
				_HMG_SYSDATA [ 257 ] := .T. , ;
				PickPropertyValue.Release ;
				) 


		Define Label Legend
			Row 10
			Col 10
			Value Legend
		End Label

		Define ComboBox PickValue
			Row 35
			Col 10
			Width 270
			Height 120
			Items Options
			Value InitValue
		End ComboBox

		Define Button Ok
			Row 70
			Col 70
			Caption aMsgs [ 116 ] 
			Action	( ;
				RetVal := PickPropertyValue.PickValue.Item( PickPropertyValue.PickValue.Value ) , ;
				_HMG_SYSDATA [ 257 ] := .F. , ;
				PickPropertyValue.Release ;
				) 
		End Button

		Define Button Cancel
			Row 70
			Col 180
			Caption aMsgs [ 117 ]
			Action	( ;
				RetVal := '' , ;
				_HMG_SYSDATA [ 257 ] := .T. , ;
				PickPropertyValue.Release ;
				) 
		End Button

	End Window

	PickPropertyValue.Center

	PickPropertyValue.Activate

RETURN RetVal

*------------------------------------------------------------------------------*
FUNCTION PickNumericPropertyValue ( Title , Legend , CurrentValue )
*------------------------------------------------------------------------------*
Local RetVal 

	Define Window PickPropertyValue ;
		At 0,0 ;
		Width 300 ;
		Height GetTitleHeight() + 115 + 2 ;
		Title Title ;
		Modal ;
		NoSize ;
		NoSysMenu

		ON KEY RETURN	Action ( ;
				RetVal := ALLTRIM(STR(PickPropertyValue.PickValue.Value)) , ;
				_HMG_SYSDATA [ 257 ] := .F. , ;
				PickPropertyValue.Release ;
				) 

		ON KEY ESCAPE	Action	( ;
				RetVal := '' , ;
				_HMG_SYSDATA [ 257 ] := .T. , ;
				PickPropertyValue.Release ;
				) 

		Define Label Legend
			Row 10
			Col 10
			Value Legend
		End Label

		Define Spinner PickValue
			Row 35
			Col 10
			Width 270
			RangeMin 0
			RangeMax 0x7FFFFFFF
			Value VAL ( CurrentValue )
		End Spinner

		Define Button Ok
			Row 70
			Col 70
			Caption aMsgs [ 116 ]
			Action	( ;
				RetVal := ALLTRIM(STR(PickPropertyValue.PickValue.Value)) , ;
				_HMG_SYSDATA [ 257 ] := .F. , ;
				PickPropertyValue.Release ;
				) 
		End Button

		Define Button Cancel
			Row 70
			Col 180
			Caption aMsgs [ 117 ]
			Action	( ;
				RetVal := '' , ;
				_HMG_SYSDATA [ 257 ] := .T. , ;
				PickPropertyValue.Release ;
				) 
		End Button

	End Window

	PickPropertyValue.Cancel.SetFocus
	InsertTab()

	PickPropertyValue.Center
	PickPropertyValue.Activate

RETURN RetVal

*------------------------------------------------------------------------------*
FUNCTION PickCharacterPropertyValue ( Title , Legend , CurrentValue )
*------------------------------------------------------------------------------*
Local RetVal 

	Define Window PickPropertyValue ;
		At 0,0 ;
		Width 300 ;
		Height GetTitleHeight() + 115 + 2 ;
		Title Title ;
		Modal ;
		NoSize ;
		NoSysMenu

		ON KEY RETURN	Action ( ;
				RetVal := ALLTRIM(PickPropertyValue.PickValue.Value) , ;
				_HMG_SYSDATA [ 257 ] := .F. , ;
				PickPropertyValue.Release ;
				) 

		ON KEY ESCAPE	Action	( ;
				RetVal := '' , ;
				_HMG_SYSDATA [ 257 ] := .T. , ;
				PickPropertyValue.Release ;
				) 

		Define Label Legend
			Row 10
			Col 10
			Value Legend
		End Label

		Define TextBox PickValue
			Row 35
			Col 10
			Width 270
			Value CurrentValue
		End TextBox

		Define Button Ok
			Row 70
			Col 70
			Caption aMsgs [ 116 ]
			Action	( ;
				RetVal := ALLTRIM(PickPropertyValue.PickValue.Value) , ;
				_HMG_SYSDATA [ 257 ] := .F. , ;
				PickPropertyValue.Release ;
				) 
		End Button

		Define Button Cancel
			Row 70
			Col 180
			Caption aMsgs [ 117 ]
			Action	( ;
				RetVal := '' , ;
				_HMG_SYSDATA [ 257 ] := .T. , ;
				PickPropertyValue.Release ;
				) 
		End Button

	End Window

	PickPropertyValue.PickValue.SetFocus

	PickPropertyValue.Center
	PickPropertyValue.Activate

RETURN RetVal

*------------------------------------------------------------------------------*
FUNCTION PickColorValue ( cPropertyName )
*------------------------------------------------------------------------------*
Local RetVal 

	DEFINE WINDOW _PICKCOLOR AT 0,0 WIDTH 368 HEIGHT 74 TITLE aMsgs [ 130 ] + ' : ' +  cPropertyName MODAL NOSIZE NOSYSMENU

		DEFINE BUTTON DEFAULT
			ROW	10
			COL	10
			CAPTION	aMsgs [ 224 ]
			ACTION	( RetVal := 'Nil' , _HMG_SYSDATA [ 257 ] := .F. , _PICKCOLOR.RELEASE )
		END BUTTON

		DEFINE BUTTON OTHER
			ROW	10
			COL	130
			CAPTION	aMsgs [ 225 ]
			ACTION	( RetVal := PickColorOther() , If ( Empty(RetVal) , Nil , ( _HMG_SYSDATA [ 257 ] := .F. , _PICKCOLOR.RELEASE ) ) )
		END BUTTON

		DEFINE BUTTON CANCEL
			ROW	10
			COL	250
			CAPTION	aMsgs [ 117 ]
			ACTION	( RetVal := '' , _HMG_SYSDATA [ 257 ] := .T. , _PICKCOLOR.RELEASE )
		END BUTTON

	END WINDOW

	CENTER WINDOW _PICKCOLOR

	ACTIVATE WINDOW _PICKCOLOR

RETURN RetVal

FUNCTION PickColorOther()
Local TmpVal, RetVal

	TmpVal := GetColor ()

	If TmpVal [1] == NIL
		RetVal := ''
	Else
		RetVal := '{' + ALLTRIM(STR(TmpVal[1])) + ',' + ALLTRIM(STR(TmpVal[2])) + ',' + ALLTRIM(STR(TmpVal[3])) + '}' 
	EndIf

RETURN RetVal
