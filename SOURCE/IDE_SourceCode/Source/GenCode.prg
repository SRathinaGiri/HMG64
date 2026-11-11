*------------------------------------------------------------------------------*
FUNCTION GenCode (i,e)
*------------------------------------------------------------------------------*
Local ControlType
Local Code := ''
Local filler
Local z
Local aProperties
Local aEvents
Local x

	if i == 0
		RETURN ''
	endif

	if e == .t.
		filler := '        '
	else
		filler := ''
	endif

*	_HMG_SYSDATA [ 39 ] value
*
*	1: CHECKBUTTON
*	2: PROGRESSBAR
*	3: PLAYER
*	4: IPADDRESS
*	5: TIMER
*	6: HYPERLINK
*	7: ACTIVEX
*	8: CHILD WINDOW
*	>10: USER

	If	_HMG_SYSDATA [ 1 ] [ i ] == 'BUTTON' .and. _HMG_SYSDATA [ 39 ] [ i ] == 0
		ControlType := 'BUTTON'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'CHECKBOX' .and. _HMG_SYSDATA [ 39 ] [ i ] == 0
		ControlType := 'CHECKBOX'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LIST'
		ControlType := 'LISTBOX'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'COMBO'
		ControlType := 'COMBOBOX'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'CHECKBOX' .and. _HMG_SYSDATA [ 39 ] [ i ] == 1
		ControlType := 'CHECKBUTTON'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'GRID'
		ControlType := 'GRID'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'SLIDER'
		ControlType := 'SLIDER'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'SPINNER'
		ControlType := 'SPINNER'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'IMAGE'
		ControlType := 'IMAGE'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'TREE'
		ControlType := 'TREE'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'DATEPICK'
		ControlType := 'DATEPICKER'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'TEXT'
		ControlType := 'TEXTBOX'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'EDIT'
		ControlType := 'EDITBOX'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 0
		ControlType := 'LABEL'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 7
		ControlType := 'ACTIVEX'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 8
		ControlType := 'WINDOW'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'BROWSE'
		ControlType := 'BROWSE'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'RADIOGROUP'
		ControlType := 'RADIOGROUP'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'FRAME'
		ControlType := 'FRAME'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'ANIMATEBOX'
		ControlType := 'ANIMATEBOX'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL'  .and. _HMG_SYSDATA [ 39 ] [ i ] == 6
		ControlType := 'HYPERLINK'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'MONTHCAL'
		ControlType := 'MONTHCALENDAR'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'RICHEDIT'
		ControlType := 'RICHEDITBOX'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 2
		ControlType := 'PROGRESSBAR'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 3
		ControlType := 'PLAYER'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 4
		ControlType := 'IPADDRESS'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'BUTTON' .and. _HMG_SYSDATA [ 39 ] [ i ] == 5
		ControlType := 'TIMER'

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] > 10
		ControlType := 'USER'

	EndIf

	Code := Code + '' + CRLF


	If ControlType = 'USER'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ALLTRIM ( HMG_UPPER ( aComponentNames [ _HMG_SYSDATA [ 39 ] [ i ] - 10 ] ) ) + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF

		z := _HMG_SYSDATA [ 39 ] [ i ] - 10

		aProperties	:= aComponentProperties	[z]
		aEvents		:= aComponentEvents	[z]

		For x := 1 To HMG_LEN ( aProperties )

			If	.Not. ( HMG_UPPER ( ALLTRIM ( aProperties [x] ) ) == 'ROW' ;
				.or. ;
				HMG_UPPER ( ALLTRIM ( aProperties [x] ) ) == 'COL' ;
				.or. ;
				HMG_UPPER ( ALLTRIM ( aProperties [x] ) ) == 'WIDTH' ;
				.or. ;
				HMG_UPPER ( ALLTRIM ( aProperties [x] ) ) == 'HEIGHT' ;
				.or. ;
				HMG_UPPER ( ALLTRIM ( aProperties [x] ) ) == 'NAME' )

				Code := Code + filler + '        ' + HMG_UPPER ( ALLTRIM ( aProperties [x] ) )  + ' ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + HMG_UPPER ( ALLTRIM ( aProperties [x] ) ) ) + CRLF

			EndIf

		Next x

		For x := 1 To HMG_LEN ( aEvents )

			Code := Code + filler + '        ' + HMG_UPPER ( ALLTRIM ( aEvents [x] ) )  + ' ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + HMG_UPPER ( ALLTRIM ( aEvents [x] ) ) ) + CRLF

		Next x


	//.....................................................................
	Elseif ControlType = 'TREE'
	//.....................................................................

		Code := Code + filler +'    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + ' AT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + ' , ' +  ALLTRIM(STR(GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ))) + ' WIDTH ' + ALLTRIM(STR(GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ))) + ' HEIGHT ' + ALLTRIM(STR(GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ))) + ' VALUE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' )  + ' FONT ' + chr(34) + __MVGET (_HMG_SYSDATA [   2 ] [ i ]  + 'FontName') + chr(34) + ' SIZE ' + __MVGET (_HMG_SYSDATA [   2 ] [ i ]  + 'FontSize') + IF ( ALLTRIM(HMG_UPPER(__MVGET(_HMG_SYSDATA [   2 ][i]+'FontBold'))) =='.T.',' BOLD','') + IF ( ALLTRIM(HMG_UPPER(__MVGET(_HMG_SYSDATA [   2 ][i]+'FontItalic'))) =='.T.',' ITALIC','') + IF ( ALLTRIM(HMG_UPPER(__MVGET(_HMG_SYSDATA [   2 ][i]+'FontUnderLine'))) =='.T.',' UNDERLINE','') + IF ( ALLTRIM(HMG_UPPER(__MVGET(_HMG_SYSDATA [   2 ][i]+'FontStrikeOut'))) =='.T.',' STRIKEOUT','') + ' TOOLTIP ' + chr(34) + __MVGET (_HMG_SYSDATA [   2 ] [ i ]  + 'ToolTip') + chr(34)  + ' ON GOTFOCUS ' + __MVGET( _HMG_SYSDATA [   2 ] [ i ]  + 'OnGotFocus' )  + ' ON CHANGE ' + __MVGET( _HMG_SYSDATA [   2 ] [ i ]  + 'OnChange' ) + ' ON LOSTFOCUS ' + __MVGET( _HMG_SYSDATA [   2 ] [ i ]  + 'OnLostFocus' ) + ' ON DBLCLICK ' + __MVGET( _HMG_SYSDATA [   2 ] [ i ]  + 'OnDblClick' ) + ' NODEIMAGES ' + __MVGET( _HMG_SYSDATA [   2 ] [ i ]  + 'NodeImages' ) + ' ITEMIMAGES ' + __MVGET( _HMG_SYSDATA [   2 ] [ i ]  + 'ItemImages' ) + if ( ALLTRIM(HMG_UPPER(__MVGET( _HMG_SYSDATA [   2 ] [ i ] + 'RootButton' ))) == '.T.' , '' , ' NOROOTBUTTON' ) + if ( ALLTRIM(HMG_UPPER(__MVGET( _HMG_SYSDATA [   2 ] [ i ] + 'ItemIds' ))) == '.T.' , ' ITEMIDS' , '' ) + ' HELPID ' + __MVGET( _HMG_SYSDATA [   2 ] [ i ]  + 'HelpId' )  + CRLF

	//.....................................................................
	ElseIf ControlType = 'TIMER'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + ' INTERVAL ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Interval' ) + ' ACTION ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Action' ) + CRLF

	//.....................................................................
	ElseIf ControlType = 'BUTTON'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        ACTION ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Action' ) + CRLF
		if empty ( __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Caption' ) )
			Code := Code + filler + '        CAPTION Nil' + CRLF
		else
                        Code := Code + filler + '        CAPTION ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Caption' ) + chr(34) + CRLF
		endif
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF
		Code := Code + filler + '        ONGOTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnGotFocus' ) + CRLF
		Code := Code + filler + '        ONLOSTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnLostFocus' ) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        FLAT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Flat' ) + CRLF
		Code := Code + filler + '        TABSTOP ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TabStop' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF
		Code := Code + filler + '        TRANSPARENT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Transparent' ) + CRLF
		Code := Code + filler + '        MULTILINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'MultiLine' ) + CRLF

		if empty ( __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Picture' ) )
			Code := Code + filler + '        PICTURE Nil' + CRLF
		else
			Code := Code + filler + '        PICTURE ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Picture' ) + chr(34) + CRLF
		endif

		Code := Code + filler + '        PICTALIGNMENT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'PictAlignment' ) + CRLF

	//.....................................................................
	ElseIf ControlType = 'CHECKBOX'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        CAPTION ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Caption' ) + chr(34) + CRLF
		Code := Code + filler + '        VALUE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + CRLF
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        ONCHANGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnChange' ) + CRLF
		Code := Code + filler + '        ONGOTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnGotFocus' ) + CRLF
		Code := Code + filler + '        ONLOSTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnLostFocus' ) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Field' ))
			if ALLTRIM(HMG_UPPER(__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Field' ))) != 'NIL'
				Code := Code + filler + '        FIELD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Field' ) + CRLF
			endif
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ))
			Code := Code + filler + '        BACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ) + CRLF
		Else
			Code := Code + filler + '        BACKCOLOR NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ))
			Code := Code + filler + '        FONTCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ) + CRLF
		Else
			Code := Code + filler + '        FONTCOLOR NIL' + CRLF
		EndIf

		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        TABSTOP ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TabStop' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF
		Code := Code + filler + '        TRANSPARENT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Transparent' ) + CRLF

	//.....................................................................
	ElseIf ControlType = 'LISTBOX'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        ITEMS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Items' ) + CRLF
		Code := Code + filler + '        VALUE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + CRLF
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        ONCHANGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnChange' ) + CRLF
		Code := Code + filler + '        ONGOTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnGotFocus' ) + CRLF
		Code := Code + filler + '        ONLOSTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnLostFocus' ) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ))
			Code := Code + filler + '        BACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ) + CRLF
		Else
			Code := Code + filler + '        BACKCOLOR NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ))
			Code := Code + filler + '        FONTCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ) + CRLF
		Else
			Code := Code + filler + '        FONTCOLOR NIL' + CRLF
		EndIf

		Code := Code + filler + '        ONDBLCLICK ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnDblClick' ) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        TABSTOP ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TabStop' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF
		Code := Code + filler + '        SORT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Sort' ) + CRLF
		Code := Code + filler + '        MULTISELECT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'MultiSelect' ) + CRLF

		Code := Code + filler + '        DRAGITEMS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'DragItems' ) + CRLF

	//.....................................................................
	ElseIf ControlType = 'COMBOBOX'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        ITEMS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Items' ) + CRLF
		Code := Code + filler + '        VALUE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + CRLF
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        ONCHANGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnChange' ) + CRLF
		Code := Code + filler + '        ONGOTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnGotFocus' ) + CRLF
		Code := Code + filler + '        ONLOSTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnLostFocus' ) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        TABSTOP ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TabStop' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF
		Code := Code + filler + '        SORT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Sort' ) + CRLF
		Code := Code + filler + '        ONENTER ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnEnter' ) + CRLF
		Code := Code + filler + '        ONDISPLAYCHANGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnDisplayChange' ) + CRLF
		Code := Code + filler + '        DISPLAYEDIT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'DisplayEdit' ) + CRLF

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ValueSource' ))
			Code := Code + filler + '        VALUESOURCE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ValueSource' ) + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ItemSource' ))
			if ALLTRIM(HMG_UPPER(__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ItemSource' ))) != 'NIL'
				Code := Code + filler + '        ITEMSOURCE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ItemSource' ) + CRLF
			endif
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Image' ))
			Code := Code + filler + '        IMAGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Image' ) + CRLF
		Else
			Code := Code + filler + '        IMAGE NIL' + CRLF
		EndIf

		Code := Code + filler + '        DROPPEDWIDTH ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'DroppedWidth' ) + CRLF

		Code := Code + filler + '        ONDROPDOWN ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnDropDown' ) + CRLF
		Code := Code + filler + '        ONCLOSEUP ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnCloseUp' ) + CRLF


	//.....................................................................
	ElseIf ControlType = 'CHECKBUTTON'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        CAPTION ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Caption' ) + chr(34) + CRLF
		Code := Code + filler + '        VALUE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + CRLF
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        ONCHANGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnChange' ) + CRLF
		Code := Code + filler + '        ONGOTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnGotFocus' ) + CRLF
		Code := Code + filler + '        ONLOSTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnLostFocus' ) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        TABSTOP ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TabStop' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF

		if empty ( __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Picture' ) )
			Code := Code + filler + '        PICTURE Nil' + CRLF
		else
			Code := Code + filler + '        PICTURE ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Picture' ) + chr(34) + CRLF
		endif

	//.....................................................................
	ElseIf ControlType = 'GRID'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        ITEMS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Items' ) + CRLF
		Code := Code + filler + '        VALUE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + CRLF
		Code := Code + filler + '        WIDTHS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Widths' ) + CRLF
		Code := Code + filler + '        HEADERS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Headers' ) + CRLF
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        ONCHANGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnChange' ) + CRLF
		Code := Code + filler + '        ONGOTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnGotFocus' ) + CRLF
		Code := Code + filler + '        ONLOSTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnLostFocus' ) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF
		Code := Code + filler + '        ONDBLCLICK ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnDblClick' ) + CRLF
		Code := Code + filler + '        ONHEADCLICK ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnHeadClick' ) + CRLF
		Code := Code + filler + '        ONQUERYDATA ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnQueryData' ) + CRLF
		Code := Code + filler + '        MULTISELECT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'MultiSelect' ) + CRLF
		Code := Code + filler + '        ALLOWEDIT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'AllowEdit' ) + CRLF
		Code := Code + filler + '        VIRTUAL ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Virtual' ) + CRLF

		Code := Code + filler + '        DYNAMICBACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'DynamicBackColor' ) + CRLF
		Code := Code + filler + '        DYNAMICFORECOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'DynamicForeColor' ) + CRLF
		Code := Code + filler + '        COLUMNWHEN ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ColumnWhen' ) + CRLF
		Code := Code + filler + '        COLUMNVALID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ColumnValid' ) + CRLF
		Code := Code + filler + '        COLUMNCONTROLS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ColumnControls' ) + CRLF
		Code := Code + filler + '        SHOWHEADERS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ShowHeaders' ) + CRLF

		Code := Code + filler + '        CELLNAVIGATION ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'CellNavigation' ) + CRLF

		if ALLTRIM ( HMG_UPPER ( __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Lines' ) ) ) == '.T.'
			Code := Code + filler + '        NOLINES .F.' + CRLF
		else
			Code := Code + filler + '        NOLINES .T.' + CRLF
		endif

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ))
			Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Else
			Code := Code + filler + '        HELPID NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Image' ))
			Code := Code + filler + '        IMAGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Image' ) + CRLF
		Else
			Code := Code + filler + '        IMAGE NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Justify' ))
			Code := Code + filler + '        JUSTIFY ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Justify' ) + CRLF
		Else
			Code := Code + filler + '        JUSTIFY NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ItemCount' ))
			Code := Code + filler + '        ITEMCOUNT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ItemCount' ) + CRLF
		Else
			Code := Code + filler + '        ITEMCOUNT NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ))
			Code := Code + filler + '        BACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ) + CRLF
		Else
			Code := Code + filler + '        BACKCOLOR NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ))
			Code := Code + filler + '        FONTCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ) + CRLF
		Else
			Code := Code + filler + '        FONTCOLOR NIL' + CRLF
		EndIf

		Code := Code + filler + '        HEADERIMAGES ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HeaderImages' ) + CRLF

		Code := Code + filler + '        ROWSOURCE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'RowSource' ) + CRLF
		Code := Code + filler + '        COLUMNFIELDS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ColumnFields' ) + CRLF
		Code := Code + filler + '        ALLOWAPPEND ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'AllowAppend' ) + CRLF
		Code := Code + filler + '        ALLOWDELETE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'AllowDelete' ) + CRLF
		Code := Code + filler + '        BUFFERED ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Buffered' ) + CRLF
		Code := Code + filler + '        DYNAMICDISPLAY ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'DynamicDisplay' ) + CRLF
		Code := Code + filler + '        ONSAVE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnSave' ) + CRLF
		Code := Code + filler + '        LOCKCOLUMNS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'LockColumns' ) + CRLF

	//.....................................................................
	ElseIf ControlType = 'SLIDER'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        RANGEMIN ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'RangeMin' ) + CRLF
		Code := Code + filler + '        RANGEMAX ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'RangeMax' ) + CRLF
		Code := Code + filler + '        VALUE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        ONCHANGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnChange' ) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        TABSTOP ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TabStop' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF

		if HMG_UPPER ( ALLTRIM (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TickMarks' ))) == 'NONE'
			Code := Code + filler + '        NOTICKS .T. ' + CRLF
		ElseIf HMG_UPPER ( ALLTRIM (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TickMarks' ))) == 'BOTH'
			Code := Code + filler + '        BOTH .T. ' + CRLF
		Elseif HMG_UPPER ( ALLTRIM (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TickMarks' ))) == 'LEFT'
			Code := Code + filler + '        LEFT .T. ' + CRLF
		Elseif HMG_UPPER ( ALLTRIM (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TickMarks' ))) == 'TOP'
			Code := Code + filler + '        TOP .T. ' + CRLF
		EndIf

		if HMG_UPPER ( ALLTRIM (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Orientation' ))) == 'VERTICAL'
			Code := Code + filler + '        VERTICAL .T. ' + CRLF
		endif

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ))
			Code := Code + filler + '        BACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ) + CRLF
		Else
			Code := Code + filler + '        BACKCOLOR NIL' + CRLF
		EndIf

	//.....................................................................
	ElseIf ControlType = 'SPINNER'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        RANGEMIN ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'RangeMin' ) + CRLF
		Code := Code + filler + '        RANGEMAX ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'RangeMax' ) + CRLF
		Code := Code + filler + '        VALUE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + CRLF
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        ONCHANGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnChange' ) + CRLF
		Code := Code + filler + '        ONGOTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnGotFocus' ) + CRLF
		Code := Code + filler + '        ONLOSTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnLostFocus' ) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        TABSTOP ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TabStop' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF
		Code := Code + filler + '        WRAP ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Wrap' ) + CRLF
		Code := Code + filler + '        READONLY ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ReadOnly' ) + CRLF
		Code := Code + filler + '        INCREMENT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Increment' ) + CRLF

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ))
			Code := Code + filler + '        BACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ) + CRLF
		Else
			Code := Code + filler + '        BACKCOLOR NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ))
			Code := Code + filler + '        FONTCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ) + CRLF
		Else
			Code := Code + filler + '        FONTCOLOR NIL' + CRLF
		EndIf

	//.....................................................................
	ElseIf ControlType = 'IMAGE'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        PICTURE ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Picture' ) + chr(34) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF
		Code := Code + filler + '        STRETCH ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Stretch' ) + CRLF
		Code := Code + filler + '        ACTION ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Action' ) + CRLF

	//.....................................................................
	ElseIf ControlType = 'ACTIVEX'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        PROGID ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ProgId' ) + chr(34) + CRLF

	//.....................................................................
	ElseIf ControlType = 'WINDOW'
	//.....................................................................

		Code := Code + filler + '    LOAD WINDOW ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + ' AT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) ))  + ' , ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + ' WIDTH ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + ' HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF

	//.....................................................................
	ElseIf ControlType = 'DATEPICKER'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        VALUE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + CRLF
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        ONCHANGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnChange' ) + CRLF
		Code := Code + filler + '        ONGOTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnGotFocus' ) + CRLF
		Code := Code + filler + '        ONLOSTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnLostFocus' ) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF
		Code := Code + filler + '        ONENTER ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnEnter' ) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        TABSTOP ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TabStop' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF
		Code := Code + filler + '        SHOWNONE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ShowNone' ) + CRLF
		Code := Code + filler + '        UPDOWN ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'UpDown' ) + CRLF
		Code := Code + filler + '        RIGHTALIGN ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'RightAlign' ) + CRLF

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Field' ))
			if ALLTRIM(HMG_UPPER(__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Field' ))) != 'NIL'
				Code := Code + filler + '        FIELD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Field' ) + CRLF
			endif
		EndIf

	//.....................................................................
	ElseIf ControlType = 'TEXTBOX'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        ONCHANGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnChange' ) + CRLF
		Code := Code + filler + '        ONGOTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnGotFocus' ) + CRLF
		Code := Code + filler + '        ONLOSTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnLostFocus' ) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF
		Code := Code + filler + '        ONENTER ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnEnter' ) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        TABSTOP ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TabStop' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF
		Code := Code + filler + '        READONLY ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ReadOnly' ) + CRLF
		Code := Code + filler + '        RIGHTALIGN ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'RightAlign' ) + CRLF

		Code := Code + filler + '        DISABLEDBACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'DisabledBackColor' ) + CRLF
		Code := Code + filler + '        DISABLEDFONTCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'DisabledFontColor' ) + CRLF

		Code := Code + filler + '        CASECONVERT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'CaseConvert' ) + CRLF

		if ALLTRIM(HMG_UPPER(__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Password' ))) == '.T.'
			Code := Code + filler + '        PASSWORD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Password' ) + CRLF
		endif

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'MaxLength' ))
			if ALLTRIM(HMG_UPPER(__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'MaxLength' ))) != 'NIL'
				Code := Code + filler + '        MAXLENGTH ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'MaxLength' ) + CRLF
			endif
		endif

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ))
			Code := Code + filler + '        BACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ) + CRLF
		Else
			Code := Code + filler + '        BACKCOLOR NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ))
			Code := Code + filler + '        FONTCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ) + CRLF
		Else
			Code := Code + filler + '        FONTCOLOR NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Field' ))
			if ALLTRIM(HMG_UPPER(__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Field' ))) != 'NIL'
				Code := Code + filler + '        FIELD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Field' ) + CRLF
			endif
		EndIf

		if empty ( __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'InputMask' ) )
			Code := Code + filler + '        INPUTMASK Nil' + CRLF
		else
			Code := Code + filler + '        INPUTMASK ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'InputMask' ) + chr(34) + CRLF
		endif

		if empty ( __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Format' ) )
			Code := Code + filler + '        FORMAT Nil' + CRLF
		else
			Code := Code + filler + '        FORMAT ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Format' ) + chr(34) + CRLF
		endif
		
		if HMG_UPPER (ALLTRIM(__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'DataType' ))) == 'NUMERIC'
			Code := Code + filler + '        NUMERIC .T. ' + CRLF
			if empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ))
				Code := Code + filler + '        VALUE Nil' + CRLF
			Else
				Code := Code + filler + '        VALUE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + CRLF
			endif
		Elseif HMG_UPPER (ALLTRIM(__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'DataType' ))) == 'DATE'
			Code := Code + filler + '        DATE .T. ' + CRLF
			if empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ))
				Code := Code + filler + '        VALUE Nil' + CRLF
			Else
				Code := Code + filler + '        VALUE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + CRLF
			endif
		Elseif HMG_UPPER (ALLTRIM(__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'DataType' ))) == 'CHARACTER'
			Code := Code + filler + '        VALUE ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + chr(34) + CRLF
		endif

	//.....................................................................
	ElseIf ControlType = 'EDITBOX'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        VALUE ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        ONCHANGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnChange' ) + CRLF
		Code := Code + filler + '        ONGOTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnGotFocus' ) + CRLF
		Code := Code + filler + '        ONLOSTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnLostFocus' ) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        TABSTOP ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TabStop' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF
		Code := Code + filler + '        READONLY ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ReadOnly' ) + CRLF

		Code := Code + filler + '        HSCROLLBAR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HScrollBar' ) + CRLF
		Code := Code + filler + '        VSCROLLBAR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'VScrollBar' ) + CRLF

		Code := Code + filler + '        DISABLEDBACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'DisabledBackColor' ) + CRLF
		Code := Code + filler + '        DISABLEDFONTCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'DisabledFontColor' ) + CRLF

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ))
			Code := Code + filler + '        BACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ) + CRLF
		Else
			Code := Code + filler + '        BACKCOLOR NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ))
			Code := Code + filler + '        FONTCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ) + CRLF
		Else
			Code := Code + filler + '        FONTCOLOR NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'MaxLength' ))
			if ALLTRIM(HMG_UPPER(__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'MaxLength' ))) != 'NIL'
				Code := Code + filler + '        MAXLENGTH ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'MaxLength' ) + CRLF
			endif
		endif

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Field' ))
			if ALLTRIM(HMG_UPPER(__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Field' ))) != 'NIL'
				Code := Code + filler + '        FIELD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Field' ) + CRLF
			endif
		EndIf

	//.....................................................................
	ElseIf ControlType = 'LABEL'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        VALUE ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF
		Code := Code + filler + '        TRANSPARENT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Transparent' ) + CRLF
		Code := Code + filler + '        ACTION ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Action' ) + CRLF
		Code := Code + filler + '        AUTOSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'AutoSize' ) + CRLF

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ))
			Code := Code + filler + '        BACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ) + CRLF
		Else
			Code := Code + filler + '        BACKCOLOR NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ))
			Code := Code + filler + '        FONTCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ) + CRLF
		Else
			Code := Code + filler + '        FONTCOLOR NIL' + CRLF
		EndIf

		If HMG_UPPER ( ALLTRIM (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Alignment' ))) == 'RIGHT'
			Code := Code + filler + '        RIGHTALIGN .T. ' + CRLF
		Elseif HMG_UPPER ( ALLTRIM (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Alignment' ))) == 'CENTER'
			Code := Code + filler + '        CENTERALIGN .T. ' + CRLF
		EndIf

	//.....................................................................
	ElseIf ControlType = 'BROWSE'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        VALUE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + CRLF
		Code := Code + filler + '        WIDTHS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Widths' ) + CRLF
		Code := Code + filler + '        HEADERS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Headers' ) + CRLF
		Code := Code + filler + '        WORKAREA ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'WorkArea' ) + CRLF
		Code := Code + filler + '        FIELDS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Fields' ) + CRLF
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        ONCHANGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnChange' ) + CRLF
		Code := Code + filler + '        ONGOTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnGotFocus' ) + CRLF
		Code := Code + filler + '        ONLOSTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnLostFocus' ) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF
		Code := Code + filler + '        ONDBLCLICK ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnDblClick' ) + CRLF
		Code := Code + filler + '        ALLOWEDIT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'AllowEdit' ) + CRLF
		Code := Code + filler + '        ALLOWAPPEND ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'AllowAppend' ) + CRLF
		Code := Code + filler + '        ONHEADCLICK ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnHeadClick' ) + CRLF
		Code := Code + filler + '        ALLOWDELETE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'AllowDelete' ) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        VALID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Valid' ) + CRLF
		Code := Code + filler + '        VALIDMESSAGES ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ValidMessages' ) + CRLF
		Code := Code + filler + '        LOCK ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Lock' ) + CRLF
		Code := Code + filler + '        VSCROLLBAR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'vScrollBar' ) + CRLF

		Code := Code + filler + '        DYNAMICBACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'DynamicBackColor' ) + CRLF
		Code := Code + filler + '        DYNAMICFORECOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'DynamicForeColor' ) + CRLF

		Code := Code + filler + '        INPUTMASK ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'InputMask' ) + CRLF

		Code := Code + filler + '        FORMAT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Format' ) + CRLF

		Code := Code + filler + '        WHEN ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'When' ) + CRLF

		Code := Code + filler + '        INPUTITEMS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'InputItems' ) + CRLF
		Code := Code + filler + '        DISPLAYITEMS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'DisplayItems' ) + CRLF

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ))
			Code := Code + filler + '        BACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ) + CRLF
		Else
			Code := Code + filler + '        BACKCOLOR NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ))
			Code := Code + filler + '        FONTCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ) + CRLF
		Else
			Code := Code + filler + '        FONTCOLOR NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Image' ))
			Code := Code + filler + '        IMAGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Image' ) + CRLF
		Else
			Code := Code + filler + '        IMAGE NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Justify' ))
			Code := Code + filler + '        JUSTIFY ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Justify' ) + CRLF
		Else
			Code := Code + filler + '        JUSTIFY NIL' + CRLF
		EndIf

		if ALLTRIM ( HMG_UPPER ( __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Lines' ) ) ) == '.T.'
			Code := Code + filler + '        NOLINES .F.' + CRLF
		else
			Code := Code + filler + '        NOLINES .T.' + CRLF
		endif

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ReadOnlyFields' ))
			Code := Code + filler + '        READONLYFIELDS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ReadOnlyFields' ) + CRLF
		Else
			Code := Code + filler + '        READONLYFIELDS NIL' + CRLF
		EndIf

		Code := Code + filler + '        HEADERIMAGES ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HeaderImages' ) + CRLF

	//.....................................................................
	ElseIf ControlType = 'RADIOGROUP'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        OPTIONS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Options' ) + CRLF
		Code := Code + filler + '        VALUE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + CRLF
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        ONCHANGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnChange' ) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        TABSTOP ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TabStop' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF
		Code := Code + filler + '        TRANSPARENT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Transparent' ) + CRLF
		Code := Code + filler + '        SPACING ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Spacing' ) + CRLF

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ))
			Code := Code + filler + '        BACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ) + CRLF
		Else
			Code := Code + filler + '        BACKCOLOR NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ))
			Code := Code + filler + '        FONTCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ) + CRLF
		Else
			Code := Code + filler + '        FONTCOLOR NIL' + CRLF
		EndIf

		Code := Code + filler + '        READONLY ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ReadOnly' ) + CRLF

		if HMG_UPPER ( ALLTRIM (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Orientation' ))) == 'HORIZONTAL'
			Code := Code + filler + '        HORIZONTAL .T. ' + CRLF
		else
			Code := Code + filler + '        HORIZONTAL .F. ' + CRLF
		endif

	//.....................................................................
	ElseIf ControlType = 'FRAME'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF

		if Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Caption' ))
			Code := Code + filler + '        CAPTION NIL' + CRLF
		Else
			Code := Code + filler + '        CAPTION ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Caption' ) + chr(34) + CRLF
		EndIf



		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ))
			Code := Code + filler + '        BACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ) + CRLF
		Else
			Code := Code + filler + '        BACKCOLOR NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ))
			Code := Code + filler + '        FONTCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ) + CRLF
		Else
			Code := Code + filler + '        FONTCOLOR NIL' + CRLF
		EndIf

		if HMG_UPPER ( ALLTRIM (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Transparent' ) ) ) = '.F.'
			Code := Code + filler + '        OPAQUE .T.' + CRLF
		else
			Code := Code + filler + '        OPAQUE .F.' + CRLF
		EndIf

	//.....................................................................
	ElseIf ControlType = 'ANIMATEBOX'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        FILE ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'File' ) + chr(34) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        TRANSPARENT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Transparent' ) + CRLF
		Code := Code + filler + '        AUTOPLAY ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'AutoPlay' ) + CRLF
		Code := Code + filler + '        CENTER ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Center' ) + CRLF

	//.....................................................................
	ElseIf ControlType = 'HYPERLINK'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        VALUE ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + chr(34) + CRLF
		Code := Code + filler + '        ADDRESS ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Address' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF
		Code := Code + filler + '        AUTOSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'AutoSize' ) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF
		Code := Code + filler + '        HANDCURSOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HandCursor' ) + CRLF

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ))
			Code := Code + filler + '        BACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ) + CRLF
		Else
			Code := Code + filler + '        BACKCOLOR NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ))
			Code := Code + filler + '        FONTCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontColor' ) + CRLF
		Else
			Code := Code + filler + '        FONTCOLOR NIL' + CRLF
		EndIf

	//.....................................................................
	ElseIf ControlType = 'MONTHCALENDAR'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        VALUE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + CRLF
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        ONCHANGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnChange' ) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        TABSTOP ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TabStop' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF

		if HMG_UPPER ( ALLTRIM (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Today' ) ) ) = '.T.'
			Code := Code + filler + '        NOTODAY .F.' + CRLF
		else
			Code := Code + filler + '        NOTODAY .T.' + CRLF
		EndIf

		if HMG_UPPER ( ALLTRIM (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TodayCircle' ) ) ) = '.T.'
			Code := Code + filler + '        NOTODAYCIRCLE .F.' + CRLF
		else
			Code := Code + filler + '        NOTODAYCIRCLE .T.' + CRLF
		EndIf

		if HMG_UPPER ( ALLTRIM (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'WeekNumbers' ) ) ) = '.T.'
			Code := Code + filler + '        WEEKNUMBERS .T.' + CRLF
		else
			Code := Code + filler + '        WEEKNUMBERS .F.' + CRLF
		EndIf

	//.....................................................................
	ElseIf ControlType = 'RICHEDITBOX'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        VALUE ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        ONCHANGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnChange' ) + CRLF
		Code := Code + filler + '        ONGOTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnGotFocus' ) + CRLF
		Code := Code + filler + '        ONLOSTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnLostFocus' ) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        TABSTOP ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TabStop' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF
		Code := Code + filler + '        READONLY ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ReadOnly' ) + CRLF

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ))
			Code := Code + filler + '        BACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ) + CRLF
		Else
			Code := Code + filler + '        BACKCOLOR NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'MaxLength' ))
			if ALLTRIM(HMG_UPPER(__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'MaxLength' ))) != 'NIL'
				Code := Code + filler + '        MAXLENGTH ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'MaxLength' ) + CRLF
			endif
		endif

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Field' ))
			if ALLTRIM(HMG_UPPER(__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Field' ))) != 'NIL'
				Code := Code + filler + '        FIELD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Field' ) + CRLF
			endif
		EndIf

	//.....................................................................
	ElseIf ControlType = 'PROGRESSBAR'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        RANGEMIN ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'RangeMin' ) + CRLF
		Code := Code + filler + '        RANGEMAX ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'RangeMax' ) + CRLF
		Code := Code + filler + '        VALUE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF
		Code := Code + filler + '        SMOOTH ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Smooth' ) + CRLF

		if HMG_UPPER ( ALLTRIM (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Orientation' ))) == 'VERTICAL'
			Code := Code + filler + '        VERTICAL .T. ' + CRLF
		else
			Code := Code + filler + '        VERTICAL .F. ' + CRLF
		endif

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ))
			Code := Code + filler + '        BACKCOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'BackColor' ) + CRLF
		Else
			Code := Code + filler + '        BACKCOLOR NIL' + CRLF
		EndIf

		if !Empty (__MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ForeColor' ))
			Code := Code + filler + '        FORECOLOR ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ForeColor' ) + CRLF
		Else
			Code := Code + filler + '        FORECOLOR NIL' + CRLF
		EndIf

	//.....................................................................
	ElseIf ControlType = 'PLAYER'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        FILE ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'File' ) + chr(34) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF

		If ALLTRIM( HMG_UPPER ( __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'AutoSizeWindow' ) ) ) == '.T.'
			Code := Code + filler + '        NOAUTOSIZEWINDOW .F.' + CRLF
		Else
			Code := Code + filler + '        NOAUTOSIZEWINDOW .T.' + CRLF
		EndIf
		If ALLTRIM( HMG_UPPER ( __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'AutoSizeMovie' ) ) ) == '.T.'
			Code := Code + filler + '        NOAUTOSIZEMOVIE .F.' + CRLF
		Else
			Code := Code + filler + '        NOAUTOSIZEMOVIE .T.' + CRLF
		EndIf
		If ALLTRIM( HMG_UPPER ( __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ErrorDlg' ) ) ) == '.T.'
			Code := Code + filler + '        NOERRORDLG .F.' + CRLF
		Else
			Code := Code + filler + '        NOERRORDLG .T.' + CRLF
		EndIf
		If ALLTRIM( HMG_UPPER ( __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Menu' ) ) ) == '.T.'
			Code := Code + filler + '        NOMENU .F.' + CRLF
		Else
			Code := Code + filler + '        NOMENU .T.' + CRLF
		EndIf
		If ALLTRIM( HMG_UPPER ( __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Open' ) ) ) == '.T.'
			Code := Code + filler + '        NOOPEN .F.' + CRLF
		Else
			Code := Code + filler + '        NOOPEN .T.' + CRLF
		EndIf
		If ALLTRIM( HMG_UPPER ( __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Playbar' ) ) ) == '.T.'
			Code := Code + filler + '        NOPLAYBAR .F.' + CRLF
		Else
			Code := Code + filler + '        NOPLAYBAR .T.' + CRLF
		EndIf
		If ALLTRIM( HMG_UPPER ( __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ShowAll' ) ) ) == '.T.'
			Code := Code + filler + '        SHOWALL .T.' + CRLF
		Else
			Code := Code + filler + '        SHOWALL .F.' + CRLF
		EndIf
		If ALLTRIM( HMG_UPPER ( __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ShowMode' ) ) ) == '.T.'
			Code := Code + filler + '        SHOWMODE .T.' + CRLF
		Else
			Code := Code + filler + '        SHOWMODE .F.' + CRLF
		EndIf
		If ALLTRIM( HMG_UPPER ( __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ShowName' ) ) ) == '.T.'
			Code := Code + filler + '        SHOWNAME .T.' + CRLF
		Else
			Code := Code + filler + '        SHOWNAME .F.' + CRLF
		EndIf
		If ALLTRIM( HMG_UPPER ( __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Showposition' ) ) ) == '.T.'
			Code := Code + filler + '        SHOWPOSITION .T.' + CRLF
		Else
			Code := Code + filler + '        SHOWPOSITION .F.' + CRLF
		EndIf

	//.....................................................................
	ElseIf ControlType = 'IPADDRESS'
	//.....................................................................

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF
		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF
		Code := Code + filler + '        VALUE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Value' ) + CRLF
		Code := Code + filler + '        FONTNAME ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontName' ) + chr(34) + CRLF
		Code := Code + filler + '        FONTSIZE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontSize' ) + CRLF
		Code := Code + filler + '        TOOLTIP ' + chr(34) + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'ToolTip' ) + chr(34) + CRLF
		Code := Code + filler + '        ONCHANGE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnChange' ) + CRLF
		Code := Code + filler + '        ONGOTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnGotFocus' ) + CRLF
		Code := Code + filler + '        ONLOSTFOCUS ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'OnLostFocus' ) + CRLF
		Code := Code + filler + '        FONTBOLD ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontBold' ) + CRLF
		Code := Code + filler + '        FONTITALIC ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontItalic' ) + CRLF
		Code := Code + filler + '        FONTUNDERLINE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontUnderLine' ) + CRLF
		Code := Code + filler + '        FONTSTRIKEOUT ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'FontStrikeout' ) + CRLF
		Code := Code + filler + '        HELPID ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'HelpId' ) + CRLF
		Code := Code + filler + '        TABSTOP ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'TabStop' ) + CRLF
		Code := Code + filler + '        VISIBLE ' + __MVGET ( _HMG_SYSDATA [   2 ] [ i ] + 'Visible' ) + CRLF

	Else

		Code := Code + filler + '    DEFINE ' + ControlType + ' ' + ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) + CRLF

		Code := Code + filler + '        ROW    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) + CRLF
		Code := Code + filler + '        COL    ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ) )) + CRLF
		Code := Code + filler + '        WIDTH  ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ) )) + CRLF
		Code := Code + filler + '        HEIGHT ' + ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ) )) + CRLF

	EndIf


	If ControlType == 'USER'

		Code := Code + filler + '    END ' + ALLTRIM ( HMG_UPPER ( aComponentNames [ _HMG_SYSDATA [ 39 ] [ i ] - 10 ] ) ) + CRLF

	Else

		If ControlType != 'TIMER' .and. ControlType != 'WINDOW'

			Code := Code + filler + '    END ' + ControlType + CRLF

		EndIf


	EndIf

RETURN Code
