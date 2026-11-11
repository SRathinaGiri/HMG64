*------------------------------------------------------------------------------*
PROCEDURE PropertyEdit()
*------------------------------------------------------------------------------*
LOCAL Result, fmb, _OLDNAME, _NEWNAME, TabMultiline
Local i , aRow , PropertyName , PreviousValue , a , x , k , z , aTemp := {} , cTemp , x1
Local y
Local RowTemp
Local Coltemp
Local WidthTemp
Local HeightTemp
Local CaptionTemp
Local ColorTmp
Local OptTemp
Local TabName
Local TabIndex 
Local TabRow	
Local TabCol	
Local TabWidth 
Local TabHeight 
Local TabCaptions 
Local TabPage 
Local TabButtons
Local TabFlat	
Local TabHotTrack
Local TabVertical	
Local TabFontName
Local TabFontSize
Local TabBold
Local TabItalic
Local TabUnderLine
Local TabStrikeout
Local lSuccess
Local nTemp
Local b
Local c
Local d
Local e
Local aProperties
Local aEvents
Local f

	i := Properties.Grid_1.Value

	if i == 0
		RETURN
	EndIf

	aRow := Properties.Grid_1.Item (i)

	PropertyName := ALLTRIM ( HMG_UPPER ( aRow [1] ) )

	If PropertyName == 'WIDTH' .And. SelectedControlType == 'MONTHCALENDAR'
		Playhand()
		RETURN
	EndIf
	If PropertyName == 'HEIGHT' .And. SelectedControlType == 'MONTHCALENDAR'
		Playhand()
		RETURN
	EndIf
	If PropertyName == 'HEIGHT' .And. SelectedControlType == 'RADIOGROUP'
		Playhand()
		RETURN
	EndIf

	If PropertyName == 'VIRTUAL WIDTH' .And. !lVirtualForm
		Playhand()
		RETURN
	EndIf

	If PropertyName == 'VIRTUAL HEIGHT' .And. !lVirtualForm
		Playhand()
		RETURN
	EndIf

	PreviousValue := aRow [2]


	*********************************************************************
	* Begin User *
	*********************************************************************

	If SelectedControlType == 'USER'

		c := ''
				
		For b := 1 To HMG_LEN (PropertyName)

			d := HB_USUBSTR ( Propertyname , b , 1 )

			If b == 1
				d := HMG_UPPER (d)
			Else
				d := HMG_LOWER (d)
			EndIf

			c := c + d

		Next b

		If	HMG_UPPER(ALLTRIM(PropertyName)) == 'ROW' ;
			.Or. ;
			HMG_UPPER(ALLTRIM(PropertyName)) == 'COL' ;
			.Or. ;
			HMG_UPPER(ALLTRIM(PropertyName)) == 'WIDTH' ;
			.Or. ;
			HMG_UPPER(ALLTRIM(PropertyName)) == 'HEIGHT' 

			Result := ALLTRIM ( PickNumericPropertyValue ( aMsgs [ 130 ] , aRow [1] + ':' , aRow [2] ) )

			If .Not. _HMG_SYSDATA [ 257 ] == .T.

				SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
				RedrawWindow (DesignForm)
				SelectControl (SelectedControlName)

			EndIf

			RETURN

		ElseIf HMG_UPPER(ALLTRIM(PropertyName)) == 'NAME' 

			Result := ALLTRIM ( InputBox ( c + ':' , aMsgs [ 130 ] , PreviousValue ) )

			If .Not. _HMG_SYSDATA [ 257 ] == .T.
			
				b := GetControlIndex ( SelectedControlName , DesignForm )
				if b > 0

					If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)
						RETURN
					EndIf

					If !IsControNameValid ( Result ) 
						MsgStop('Control Name Duplicated or Invalid','HMG IDE')
						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)
						RETURN
					EndIf

					e := _HMG_SYSDATA [ 39 ] [ b ] - 10
					aProperties	:= aComponentProperties	[e]
					aEvents		:= aComponentEvents	[e]

					For f := 1 To HMG_LEN ( aProperties )

						If 	HMG_UPPER(ALLTRIM(aProperties [f])) <> 'ROW' ;
							.And. ;
							HMG_UPPER(ALLTRIM(aProperties [f])) <> 'COL' ;
							.And. ;
							HMG_UPPER(ALLTRIM(aProperties [f])) <> 'WIDTH' ;
							.And. ;
							HMG_UPPER(ALLTRIM(aProperties [f])) <> 'HEIGHT';
							.And. ;
							HMG_UPPER(ALLTRIM(aProperties [f])) <> 'NAME' 

							__MVPUBLIC ( Result + aProperties [f] ) 
							__MVPUT( Result + aProperties [f] ,  __MVGET ( PreviousValue + aProperties [f] ) )
							__MVXRELEASE( PreviousValue + aProperties [f] )

						EndIf

					Next f

					For f := 1 To HMG_LEN ( aEvents )

						__MVPUBLIC ( Result + aEvents [f] ) 
						__MVPUT( Result + aEvents [f] ,  __MVGET ( PreviousValue + aEvents [f] ) )
						__MVXRELEASE( PreviousValue + aEvents [f] )

					Next f

					_HMG_SYSDATA [   2 ] [b] := Result

					__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
					__MVPUT( '_' + DesignForm + '_' + Result , b )

					__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

					SelectedControlName := Result

					SetProperty ( DesignForm , SelectedControlName , 'Value' , SelectedControlName )
				
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				EndIf

			EndIf

			RETURN

		Else

			Result := ALLTRIM ( InputBox ( c + ':' , aMsgs [ 130 ] , PreviousValue ) )

			If .Not. _HMG_SYSDATA [ 257 ] == .T.
			
				__MVPUT ( SelectedControlName + PropertyName , Result )
				SelectControl (SelectedControlName)

			EndIf

		EndIf
		
		RETURN

	EndIf

	*********************************************************************
	* End User *
	*********************************************************************

	If	PropertyName == 'VISIBLE' ;
		.Or. ;
		PropertyName == 'HANDCURSOR' ;
		.Or. ;
		PropertyName == 'FLAT' ;
		.Or. ;
		PropertyName == 'SHOWHEADERS' ;
		.Or. ;
		PropertyName == 'BREAK' ;
		.Or. ;
		PropertyName == 'FOCUSED' ;
		.Or. ;
		PropertyName == 'TITLEBAR' ;
		.Or. ;
		PropertyName == 'SYSMENU' ;
		.Or. ;
		PropertyName == 'SIZABLE' ;
		.Or. ;
		PropertyName == 'MAXBUTTON' ;
		.Or. ;
		PropertyName == 'MINBUTTON' ;
		.Or. ;
		PropertyName == 'AUTORELEASE' ;
		.Or. ;
		PropertyName == 'TOPMOST' ;
		.Or. ;
		PropertyName == 'HELPBUTTON' ;
		.Or. ;
		PropertyName == 'VERTICAL' ;
		.Or. ;
		PropertyName == 'HOTTRACK' ;
		.Or. ;
		PropertyName == 'BUTTONS' ;
		.Or. ;
		PropertyName == 'CENTER' ;
		.Or. ;
		PropertyName == 'AUTOPLAY' ;
		.Or. ;
		PropertyName == 'SMOOTH' ;
		.Or. ;
		PropertyName == 'TODAY' ;
		.Or. ;
		PropertyName == 'TODAYCIRCLE' ;
		.Or. ;
		PropertyName == 'WEEKNUMBERS' ;
		.Or. ;
		PropertyName == 'AUTOSIZEWINDOW' ;
		.Or. ;
		PropertyName == 'AUTOSIZEMOVIE' ;
		.Or. ;
		PropertyName == 'ERRORDLG' ;
		.Or. ;
		PropertyName == 'MENU' ;
		.Or. ;
		PropertyName == 'OPEN' ;
		.Or. ;
		PropertyName == 'PLAYBAR' ;
		.Or. ;
		PropertyName == 'SHOWALL' ;
		.Or. ;
		PropertyName == 'SHOWMODE' ;
		.Or. ;
		PropertyName == 'SHOWNAME' ;
		.Or. ;
		PropertyName == 'SHOWPOSITION' ;
		.Or. ;
		PropertyName == 'FONTBOLD' ;
		.Or. ;
		PropertyName == 'LOCK' ;
		.Or. ;
		PropertyName == 'VSCROLLBAR' ;
		.Or. ;
		PropertyName == 'HSCROLLBAR' ;
		.Or. ;
		PropertyName == 'FONTITALIC' ;
		.Or. ;
		PropertyName == 'FONTUNDERLINE' ;
		.Or. ;
		PropertyName == 'FONTSTRIKEOUT' ;
		.Or. ;
		PropertyName == 'TABSTOP' ;
		.Or. ;
		PropertyName == 'TRANSPARENT' ;
		.Or. ;
		PropertyName == 'MULTISELECT' ;
		.Or. ;
		PropertyName == 'SORT' ;
		.Or. ;
		PropertyName == 'DISPLAYEDIT' ;
		.Or. ;
		PropertyName == 'ALLOWEDIT' ;
		.Or. ;
		PropertyName == 'ALLOWAPPEND' ;
		.Or. ;
		PropertyName == 'ALLOWDELETE' ;
		.Or. ;
		PropertyName == 'LINES' ;
		.Or. ;
		PropertyName == 'VIRTUAL' ;
		.Or. ;
		( PropertyName == 'READONLY' .And. SelectedControlType <> 'RADIOGROUP' ) ;
		.Or. ;
		PropertyName == 'WRAP' ;
		.Or. ;
		PropertyName == 'STRETCH' ;
		.Or. ;
		PropertyName == 'RIGHTALIGN' ;
		.Or. ;
		PropertyName == 'SHOWNONE' ;
		.Or. ;
		PropertyName == 'ROOTBUTTON' ;
		.Or. ;
		PropertyName == 'UPDOWN' ;
		.Or. ;
		PropertyName == 'PASSWORD' ;
		.Or. ;
		PropertyName == 'AUTOSIZE' ;
		.Or. ;
		PropertyName == 'CELLNAVIGATION' ;
		.Or. ;
		PropertyName == 'MULTILINE' ;
		.Or. ;
		PropertyName == 'DRAGITEMS' ;
		.Or. ;
		PropertyName == 'VIRTUAL SIZED' ;
		.Or. ;
		PropertyName == 'ITEMIDS' ;
		.Or. ;
		PropertyName == 'MULTILINE' ;
		.Or. ;
		PropertyName == 'BUFFERED' ;
		.Or. ;
		( PropertyName == 'VALUE' .And. SelectedControlType == 'CHECKBOX' ) ;
		.Or. ;
		( PropertyName == 'VALUE' .And. SelectedControlType == 'CHECKBUTTON' )

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 130 ] , aRow [1] + ':' , { '.T.' , '.F.' } , aRow [2] ) )

	ElseIf	PropertyName == 'CASECONVERT' 

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 130 ] , aRow [1] + ':' , { 'LOWER' , 'NONE' , 'UPPER' } , aRow [2] ) )

	ElseIf	PropertyName == 'ALIGNMENT' 

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 130 ] , aRow [1] + ':' , { 'LEFT' , 'RIGHT' , 'CENTER' } , aRow [2] ) )

	ElseIf	PropertyName == 'PICTALIGNMENT' 

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 130 ] , aRow [1] + ':' , { 'BOTTOM' , 'LEFT' , 'RIGHT' , 'TOP' } , aRow [2] ) )

	ElseIf	PropertyName == 'ROW' ;
		.Or. ;
		PropertyName == 'COL' ;
		.Or. ;
		PropertyName == 'WIDTH' ;
		.Or. ;
		PropertyName == 'LOCKCOLUMNS' ;
		.Or. ;
		PropertyName == 'DROPPEDWIDTH' ;
		.Or. ;
		PropertyName == 'VIRTUAL WIDTH' ;
		.Or. ;
		PropertyName == 'VIRTUAL HEIGHT' ;
		.Or. ;
		PropertyName == 'SPACING' ;
		.Or. ;
		PropertyName == 'HEIGHT' ;
		.Or. ;
		PropertyName == 'RANGEMAX' ;
		.Or. ;
		PropertyName == 'RANGEMIN' ;
		.Or. ;
		PropertyName == 'INCREMENT' ;
		.Or. ;
		PropertyName == 'FONTSIZE' ;
		.Or. ;
		PropertyName == 'PAGECOUNT' ;
		.Or. ;
		PropertyName == 'INTERVAL' ;
		.Or. ;
		PropertyName == 'MAXLENGTH' ;
		.Or. ;
		( PropertyName == 'VALUE' .And. SelectedControlType == 'BROWSE' ) ;
		.Or. ;
		( PropertyName == 'VALUE' .And. SelectedControlType == 'TAB' ) ;
		.Or. ;
		( PropertyName == 'VALUE' .And. SelectedControlType == 'TREE' ) ;
		.Or. ;
		( PropertyName == 'VALUE' .And. SelectedControlType == 'RADIOGROUP' ) ;
		.Or. ;
		( PropertyName == 'VALUE' .And. SelectedControlType == 'COMBOBOX' ) ;
		.Or. ;
		( PropertyName == 'VALUE' .And. SelectedControlType == 'SLIDER' ) ;
		.Or. ;
		( PropertyName == 'VALUE' .And. SelectedControlType == 'SPINNER' ) ;
		.Or. ;
		( PropertyName == 'VALUE' .And. SelectedControlType == 'PROGRESSBAR' ) ;
		.Or. ;
		( PropertyName == 'VALUE' .And. SelectedControlType == 'LISTBOX' ) 


		Result := ALLTRIM ( PickNumericPropertyValue ( aMsgs [ 130 ] , aRow [1] + ':' , aRow [2] ) )
		

	ElseIf PropertyName == 'WINDOWTYPE'

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 130 ] , aRow [1] + ':' , { 'CHILD' , 'MAIN' , 'MODAL' , 'SPLITCHILD' , 'STANDARD' ,'PANEL' } , aRow [2] ) )

	ElseIf PropertyName == 'HELPBUTTON'

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 130 ] , aRow [1] + ':' , { 'CHILD' , 'MAIN' , 'MODAL' , 'SPLITCHILD' , 'STANDARD' } , aRow [2] ) )

	ElseIf PropertyName == 'DATATYPE'

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 130 ] , aRow [1] + ':' , { 'CHARACTER' , 'DATE' , 'NUMERIC' } , aRow [2] ) )

	ElseIf PropertyName == 'ORIENTATION'

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 130 ] , aRow [1] + ':' , { 'HORIZONTAL' , 'VERTICAL' } , aRow [2] ) )

	ElseIf PropertyName == 'TICKMARKS' .And. ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlname + 'Orientation' ) ) ) == 'HORIZONTAL' 

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 130 ] , aRow [1] + ':' , { 'BOTH' , 'BOTTOM' ,  'NONE' , 'TOP' } , aRow [2] ) )

	ElseIf PropertyName == 'TICKMARKS' .And. ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlname + 'Orientation' ) ) ) == 'VERTICAL'  

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 130 ] , aRow [1] + ':' , { 'BOTH' , 'LEFT' , 'NONE' , 'RIGHT' } , aRow [2] ) )

	ElseIf PropertyName == 'BACKCOLOR'

		Result := PickColorValue( aRow [1] )

	ElseIf PropertyName == 'FONTCOLOR'

		Result := PickColorValue( aRow [1] )

	ElseIf PropertyName == 'FORECOLOR'

		Result := PickColorValue( aRow [1] )

	Else

		Result := ALLTRIM ( PickCharacterPropertyValue ( aMsgs [ 130 ] , aRow [1] + ':' , aRow [2] ) )

	EndIf

	If _HMG_SYSDATA [ 257 ] == .F.

		DesignFormModified := .T.

		if ! Empty ( SelectedControlName )

			Properties.Grid_1.Item (i) := { aRow [1] , Result }

			*******************************************************
			If	SelectedControlType == 'BUTTON'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result ) 
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						__MVPUBLIC ( Result + 'Caption' ) 
						__MVPUT( Result + 'Caption' ,  __MVGET ( PreviousValue + 'Caption' ) )
						__MVXRELEASE( PreviousValue + 'Caption' )

						__MVPUBLIC ( Result + 'Action' ) 
						__MVPUT( Result + 'Action' , __MVGET ( PreviousValue + 'Action' ) )
						__MVXRELEASE( PreviousValue + 'Action' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' , __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' , __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' , __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )
				
						__MVPUBLIC ( Result + 'OnGotFocus' ) 
						__MVPUT( Result + 'OnGotFocus' , __MVGET ( PreviousValue + 'OnGotFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnGotFocus' )

						__MVPUBLIC ( Result + 'OnLostFocus' ) 
						__MVPUT( Result + 'OnLostFocus' , __MVGET ( PreviousValue + 'OnLostFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnLostFocus' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' , __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' , __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' , __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )
	
						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' , __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'Flat' ) 
						__MVPUT( Result + 'Flat' , __MVGET ( PreviousValue + 'Flat' ) )
						__MVXRELEASE( PreviousValue + 'Flat' )

						__MVPUBLIC ( Result + 'TabStop' ) 
						__MVPUT( Result + 'TabStop' , __MVGET ( PreviousValue + 'TabStop' ) )
						__MVXRELEASE( PreviousValue + 'TabStop' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' , __MVGET ( PreviousValue + 'Visible'  ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' , __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'Transparent' ) 
						__MVPUT( Result + 'Transparent' , __MVGET ( PreviousValue + 'Transparent'  ) )
						__MVXRELEASE( PreviousValue + 'Transparent' )

						__MVPUBLIC ( Result + 'Picture' ) 
						__MVPUT( Result + 'Picture' , __MVGET ( PreviousValue + 'Picture'  ) )
						__MVXRELEASE( PreviousValue + 'Picture' )

						__MVPUBLIC ( Result + 'PictAlignment' ) 
						__MVPUT( Result + 'PictAlignment' , __MVGET ( PreviousValue + 'PictAlignment'  ) )
						__MVXRELEASE( PreviousValue + 'PictAlignment' )

						__MVPUBLIC ( Result + 'MultiLine' ) 
						__MVPUT( Result + 'MultiLine' , __MVGET ( PreviousValue + 'MultiLine'  ) )
						__MVXRELEASE( PreviousValue + 'MultiLine' )


						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'CAPTION'
					__MVPUT( SelectedControlName + 'Caption' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FLAT'

					__MVPUT( SelectedControlName + 'Flat' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )
					WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
					HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )
					CaptionTemp := GetProperty ( DesignForm , SelectedControlName , 'Caption' )	

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE BUTTON &SelectedControlName
						ROW RowTemp
						COL ColTemp
						WIDTH WidthTemp
						HEIGHT HeightTemp
						CAPTION CaptionTemp 
						PARENT &DesignForm
						ON GOTFOCUS SelectControl (This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'Flat' )    )) == '.T.'
							FLAT .T.
						else
							FLAT .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'MultiLine' )    )) == '.T.'
							MULTILINE .T.
						else
							MULTILINE .F.
						endif

					END BUTTON

					if ! empty ( TabName )

						TabPage := GetProperty ( DesignForm , TabName , 'Value' )

						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )

						DrawGrid()

						_HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] := TabName
	
					EndIf

					RedrawWindow (DesignForm)
					DrawGrid()
					SelectControl (SelectedControlName)
					DrawGrid()

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TABSTOP'
					__MVPUT( SelectedControlName + 'TabStop' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TRANSPARENT'
					__MVPUT( SelectedControlName + 'Transparent' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'PICTURE'
					__MVPUT( SelectedControlName + 'Picture' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'PICTALIGNMENT'
					__MVPUT( SelectedControlName + 'PictAlignment' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'MULTILINE'

					__MVPUT( SelectedControlName + 'MultiLine' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )
					WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
					HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )
					CaptionTemp := GetProperty ( DesignForm , SelectedControlName , 'Caption' )	

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE BUTTON &SelectedControlName
						ROW RowTemp
						COL ColTemp
						WIDTH WidthTemp
						HEIGHT HeightTemp
						CAPTION CaptionTemp 
						PARENT &DesignForm
						ON GOTFOCUS SelectControl (This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'Flat' )    )) == '.T.'
							FLAT .T.
						else
							FLAT .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'MultiLine' )    )) == '.T.'
							MULTILINE .T.
						else
							MULTILINE .F.
						endif

					END BUTTON

					if ! empty ( TabName )

						TabPage := GetProperty ( DesignForm , TabName , 'Value' )

						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )

						DrawGrid()

						_HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] := TabName
	
					EndIf

					RedrawWindow (DesignForm)
					DrawGrid()
					SelectControl (SelectedControlName)
					DrawGrid()

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'CHECKBOX'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						__MVPUBLIC ( Result + 'Caption' ) 
						__MVPUT( Result + 'Caption' ,  __MVGET ( PreviousValue + 'Caption' ) )
						__MVXRELEASE( PreviousValue + 'Caption' )

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'OnChange' ) 
						__MVPUT( Result + 'OnChange' ,  __MVGET ( PreviousValue + 'OnChange' ) )
						__MVXRELEASE( PreviousValue + 'OnChange' )

						__MVPUBLIC ( Result + 'OnGotFocus' ) 
						__MVPUT( Result + 'OnGotFocus' ,  __MVGET ( PreviousValue + 'OnGotFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnGotFocus' )

						__MVPUBLIC ( Result + 'OnLostFocus' ) 
						__MVPUT( Result + 'OnLostFocus' ,  __MVGET ( PreviousValue + 'OnLostFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnLostFocus' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'Field' ) 
						__MVPUT( Result + 'Field' ,  __MVGET ( PreviousValue + 'Field' ) )
						__MVXRELEASE( PreviousValue + 'Field' )

						__MVPUBLIC ( Result + 'BackColor' ) 
						__MVPUT( Result + 'BackColor' ,  __MVGET ( PreviousValue + 'BackColor' ) )
						__MVXRELEASE( PreviousValue + 'BackColor' )

						__MVPUBLIC ( Result + 'FontColor' ) 
						__MVPUT( Result + 'FontColor' ,  __MVGET ( PreviousValue + 'FontColor' ) )
						__MVXRELEASE( PreviousValue + 'FontColor' )

						__MVPUBLIC ( Result + 'TabStop' ) 
						__MVPUT( Result + 'TabStop' ,  __MVGET ( PreviousValue + 'TabStop' ) )
						__MVXRELEASE( PreviousValue + 'TabStop' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' ,  __MVGET ( PreviousValue + 'Visible' ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'Transparent' ) 
						__MVPUT( Result + 'Transparent' ,  __MVGET ( PreviousValue + 'Transparent' ) )
						__MVXRELEASE( PreviousValue + 'Transparent' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'CAPTION'
					__MVPUT( SelectedControlName + 'Caption' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FIELD'
					__MVPUT( SelectedControlName + 'Field' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'BACKCOLOR'
					__MVPUT( SelectedControlName + 'BackColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 14 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTCOLOR'
					__MVPUT( SelectedControlName + 'FontColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 15 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TABSTOP'
					__MVPUT( SelectedControlName + 'TabStop' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TRANSPARENT'
					__MVPUT( SelectedControlName + 'Transparent' , Result )
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'LISTBOX'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						SetProperty ( DesignForm , SelectedControlName , 'Item' , 1 , Result )

						__MVPUBLIC ( Result + 'DragItems' ) 
						__MVPUT( Result + 'DragItems' ,  __MVGET ( PreviousValue + 'DragItems' ) )
						__MVXRELEASE( PreviousValue + 'DragItems' )

						__MVPUBLIC ( Result + 'Items' ) 
						__MVPUT( Result + 'Items' ,  __MVGET ( PreviousValue + 'Items' ) )
						__MVXRELEASE( PreviousValue + 'Items' )

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'OnChange' ) 
						__MVPUT( Result + 'OnChange' ,  __MVGET ( PreviousValue + 'OnChange' ) )
						__MVXRELEASE( PreviousValue + 'OnChange' )

						__MVPUBLIC ( Result + 'OnGotFocus' ) 
						__MVPUT( Result + 'OnGotFocus' ,  __MVGET ( PreviousValue + 'OnGotFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnGotFocus' )

						__MVPUBLIC ( Result + 'OnLostFocus' ) 
						__MVPUT( Result + 'OnLostFocus' ,  __MVGET ( PreviousValue + 'OnLostFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnLostFocus' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'BackColor' ) 
						__MVPUT( Result + 'BackColor' ,  __MVGET ( PreviousValue + 'BackColor' ) )
						__MVXRELEASE( PreviousValue + 'BackColor' )

						__MVPUBLIC ( Result + 'FontColor' ) 
						__MVPUT( Result + 'FontColor' ,  __MVGET ( PreviousValue + 'FontColor' ) )
						__MVXRELEASE( PreviousValue + 'FontColor' )

						__MVPUBLIC ( Result + 'OnDblClick' ) 
						__MVPUT( Result + 'OnDblClick' ,  __MVGET ( PreviousValue + 'OnDblClick' ) )
						__MVXRELEASE( PreviousValue + 'OnDblClick' )

						__MVPUBLIC ( Result + 'TabStop' ) 
						__MVPUT( Result + 'TabStop' ,  __MVGET ( PreviousValue + 'TabStop' ) )
						__MVXRELEASE( PreviousValue + 'TabStop' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' ,  __MVGET ( PreviousValue + 'Visible' ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'Sort' ) 
						__MVPUT( Result + 'Sort' ,  __MVGET ( PreviousValue + 'Sort' ) )
						__MVXRELEASE( PreviousValue + 'Sort' )

						__MVPUBLIC ( Result + 'MultiSelect' ) 
						__MVPUT( Result + 'MultiSelect' ,  __MVGET ( PreviousValue + 'MultiSelect' ) )
						__MVXRELEASE( PreviousValue + 'MultiSelect' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ITEMS'
					__MVPUT( SelectedControlName + 'Items' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'BACKCOLOR'
					__MVPUT( SelectedControlName + 'BackColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 14 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTCOLOR'
					__MVPUT( SelectedControlName + 'FontColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 15 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TABSTOP'
					__MVPUT( SelectedControlName + 'TabStop' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'SORT'
					__MVPUT( SelectedControlName + 'Sort' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'MULTISELECT'
					__MVPUT( SelectedControlName + 'MultiSelect' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'DRAGITEMS'
					__MVPUT( SelectedControlName + 'DragItems' , Result )
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'COMBOBOX'
			*******************************************************

				If PropertyName == 'ROW'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						SetProperty ( DesignForm , SelectedControlName , 'Item' , 1 , Result )
						SetProperty ( DesignForm , SelectedControlName , 'Value' , 1 )

						__MVPUBLIC ( Result + 'Items' ) 
						__MVPUT( Result + 'Items' ,  __MVGET ( PreviousValue + 'Items' ) )
						__MVXRELEASE( PreviousValue + 'Items' )

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'OnChange' ) 
						__MVPUT( Result + 'OnChange' ,  __MVGET ( PreviousValue + 'OnChange' ) )
						__MVXRELEASE( PreviousValue + 'OnChange' )

						__MVPUBLIC ( Result + 'OnGotFocus' ) 
						__MVPUT( Result + 'OnGotFocus' ,  __MVGET ( PreviousValue + 'OnGotFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnGotFocus' )

						__MVPUBLIC ( Result + 'OnLostFocus' ) 
						__MVPUT( Result + 'OnLostFocus' ,  __MVGET ( PreviousValue + 'OnLostFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnLostFocus' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'TabStop' ) 
						__MVPUT( Result + 'TabStop' ,  __MVGET ( PreviousValue + 'TabStop' ) )
						__MVXRELEASE( PreviousValue + 'TabStop' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' ,  __MVGET ( PreviousValue + 'Visible' ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'Sort' ) 
						__MVPUT( Result + 'Sort' ,  __MVGET ( PreviousValue + 'Sort' ) )
						__MVXRELEASE( PreviousValue + 'Sort' )

						__MVPUBLIC ( Result + 'OnEnter' ) 
						__MVPUT( Result + 'OnEnter' ,  __MVGET ( PreviousValue + 'OnEnter' ) )
						__MVXRELEASE( PreviousValue + 'OnEnter' )

						__MVPUBLIC ( Result + 'OnDisplayChange' ) 
						__MVPUT( Result + 'OnDisplayChange' ,  __MVGET ( PreviousValue + 'OnDisplayChange' ) )
						__MVXRELEASE( PreviousValue + 'OnDisplayChange' )

						__MVPUBLIC ( Result + 'DisplayEdit' ) 
						__MVPUT( Result + 'DisplayEdit' ,  __MVGET ( PreviousValue + 'DisplayEdit' ) )
						__MVXRELEASE( PreviousValue + 'DisplayEdit' )

						__MVPUBLIC ( Result + 'ItemSource' ) 
						__MVPUT( Result + 'ItemSource' ,  __MVGET ( PreviousValue + 'ItemSource' ) )
						__MVXRELEASE( PreviousValue + 'ItemSource' )

						__MVPUBLIC ( Result + 'ValueSource' ) 
						__MVPUT( Result + 'ValueSource' ,  __MVGET ( PreviousValue + 'ValueSource' ) )
						__MVXRELEASE( PreviousValue + 'ValueSource' )

						__MVPUBLIC ( Result + 'DroppedWidth' ) 
						__MVPUT( Result + 'DroppedWidth' ,  __MVGET ( PreviousValue + 'DroppedWidth' ) )
						__MVXRELEASE( PreviousValue + 'DroppedWidth' )

						__MVPUBLIC ( Result + 'Image' ) 
						__MVPUT( Result + 'Image' ,  __MVGET ( PreviousValue + 'Image' ) )
						__MVXRELEASE( PreviousValue + 'Image' )

						__MVPUBLIC ( Result + 'OnCloseUp' ) 
						__MVPUT( Result + 'OnCloseUp' ,  __MVGET ( PreviousValue + 'OnCloseUp' ) )
						__MVXRELEASE( PreviousValue + 'OnCloseUp' )

						__MVPUBLIC ( Result + 'OnDropDown' ) 
						__MVPUT( Result + 'OnDropDown' ,  __MVGET ( PreviousValue + 'OnDropDown' ) )
						__MVXRELEASE( PreviousValue + 'OnDropDown' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ITEMS'
					__MVPUT( SelectedControlName + 'Items' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'DROPPEDWIDTH'
					__MVPUT( SelectedControlName + 'DroppedWidth' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'IMAGE'
					__MVPUT( SelectedControlName + 'Image' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TABSTOP'
					__MVPUT( SelectedControlName + 'TabStop' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'SORT'
					__MVPUT( SelectedControlName + 'Sort' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'DISPLAYEDIT'
					__MVPUT( SelectedControlName + 'DisplayEdit' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUESOURCE'
					__MVPUT( SelectedControlName + 'ValueSource' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ITEMSOURCE'
					__MVPUT( SelectedControlName + 'ItemSource' , Result )
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'CHECKBUTTON'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						__MVPUBLIC ( Result + 'Caption' ) 
						__MVPUT( Result + 'Caption' ,  __MVGET ( PreviousValue + 'Caption' ) )
						__MVXRELEASE( PreviousValue + 'Caption' )

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'OnChange' ) 
						__MVPUT( Result + 'OnChange' ,  __MVGET ( PreviousValue + 'OnChange' ) )
						__MVXRELEASE( PreviousValue + 'OnChange' )

						__MVPUBLIC ( Result + 'OnGotFocus' ) 
						__MVPUT( Result + 'OnGotFocus' ,  __MVGET ( PreviousValue + 'OnGotFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnGotFocus' )

						__MVPUBLIC ( Result + 'OnLostFocus' ) 
						__MVPUT( Result + 'OnLostFocus' ,  __MVGET ( PreviousValue + 'OnLostFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnLostFocus' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'TabStop' ) 
						__MVPUT( Result + 'TabStop' ,  __MVGET ( PreviousValue + 'TabStop' ) )
						__MVXRELEASE( PreviousValue + 'TabStop' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' ,  __MVGET ( PreviousValue + 'Visible' ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'Picture' ) 
						__MVPUT( Result + 'Picture' ,  __MVGET ( PreviousValue + 'Picture' ) )
						__MVXRELEASE( PreviousValue + 'Picture' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'CAPTION'
					__MVPUT( SelectedControlName + 'Caption' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )

					if .Not. Empty ( Result )
						__MVPUT( SelectedControlName + 'Picture' , '' )
						Properties.Grid_1.Item(12) := { 'Picture' ,'' }
					EndIf

					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TABSTOP'
					__MVPUT( SelectedControlName + 'TabStop' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'PICTURE'
					__MVPUT( SelectedControlName + 'Picture' , Result )

					if .Not. Empty ( Result )
						__MVPUT( SelectedControlName + 'Caption' , '' )
						SetProperty ( DesignForm , SelectedControlName , 'Caption' , '' )
						Properties.Grid_1.Item(1) := { 'Caption' ,'' }
					EndIf
				
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'GRID'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						SetProperty ( DesignForm , SelectedControlName , 'Item' , 1 , { Result } )

						__MVPUBLIC ( Result + 'Items' ) 
						__MVPUT( Result + 'Items' ,  __MVGET ( PreviousValue + 'Items' ) )
						__MVXRELEASE( PreviousValue + 'Items' )

						__MVPUBLIC ( Result + 'Headers' ) 
						__MVPUT( Result + 'Headers' ,  __MVGET ( PreviousValue + 'Headers' ) )
						__MVXRELEASE( PreviousValue + 'Headers' )

						__MVPUBLIC ( Result + 'Widths' ) 
						__MVPUT( Result + 'Widths' ,  __MVGET ( PreviousValue + 'Widths' ) )
						__MVXRELEASE( PreviousValue + 'Widths' )

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'OnChange' ) 
						__MVPUT( Result + 'OnChange' ,  __MVGET ( PreviousValue + 'OnChange' ) )
						__MVXRELEASE( PreviousValue + 'OnChange' )

						__MVPUBLIC ( Result + 'OnGotFocus' ) 
						__MVPUT( Result + 'OnGotFocus' ,  __MVGET ( PreviousValue + 'OnGotFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnGotFocus' )

						__MVPUBLIC ( Result + 'OnLostFocus' ) 
						__MVPUT( Result + 'OnLostFocus' ,  __MVGET ( PreviousValue + 'OnLostFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnLostFocus' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'OnDblClick' ) 
						__MVPUT( Result + 'OnDblClick' ,  __MVGET ( PreviousValue + 'OnDblClick' ) )
						__MVXRELEASE( PreviousValue + 'OnDblClick' )

						__MVPUBLIC ( Result + 'OnHeadClick' ) 
						__MVPUT( Result + 'OnHeadClick' ,  __MVGET ( PreviousValue + 'OnHeadClick' ) )
						__MVXRELEASE( PreviousValue + 'OnHeadClick' )

						__MVPUBLIC ( Result + 'OnQueryData' ) 
						__MVPUT( Result + 'OnQueryData' ,  __MVGET ( PreviousValue + 'OnQueryData' ) )
						__MVXRELEASE( PreviousValue + 'OnQueryData' )

						__MVPUBLIC ( Result + 'MultiSelect' ) 
						__MVPUT( Result + 'MultiSelect' ,  __MVGET ( PreviousValue + 'MultiSelect' ) )
						__MVXRELEASE( PreviousValue + 'MultiSelect' )

						__MVPUBLIC ( Result + 'AllowEdit' ) 
						__MVPUT( Result + 'AllowEdit' ,  __MVGET ( PreviousValue + 'AllowEdit' ) )
						__MVXRELEASE( PreviousValue + 'AllowEdit' )

						__MVPUBLIC ( Result + 'Virtual' ) 
						__MVPUT( Result + 'Virtual' ,  __MVGET ( PreviousValue + 'Virtual' ) )
						__MVXRELEASE( PreviousValue + 'Virtual' )

						__MVPUBLIC ( Result + 'Lines' ) 
						__MVPUT( Result + 'Lines' ,  __MVGET ( PreviousValue + 'Lines' ) )
						__MVXRELEASE( PreviousValue + 'Lines' )

						__MVPUBLIC ( Result + 'Image' ) 
						__MVPUT( Result + 'Image' ,  __MVGET ( PreviousValue + 'Image' ) )
						__MVXRELEASE( PreviousValue + 'Image' )

						__MVPUBLIC ( Result + 'Justify' ) 
						__MVPUT( Result + 'Justify' ,  __MVGET ( PreviousValue + 'Justify' ) )
						__MVXRELEASE( PreviousValue + 'Justify' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'ItemCount' ) 
						__MVPUT( Result + 'ItemCount' ,  __MVGET ( PreviousValue + 'ItemCount' ) )
						__MVXRELEASE( PreviousValue + 'ItemCount' )

						__MVPUBLIC ( Result + 'BackColor' ) 
						__MVPUT( Result + 'BackColor' ,  __MVGET ( PreviousValue + 'BackColor' ) )
						__MVXRELEASE( PreviousValue + 'BackColor' )

						__MVPUBLIC ( Result + 'FontColor' ) 
						__MVPUT( Result + 'FontColor' ,  __MVGET ( PreviousValue + 'FontColor' ) )
						__MVXRELEASE( PreviousValue + 'FontColor' )

						*

						__MVPUBLIC ( Result + 'DynamicBackColor' ) 
						__MVPUT( Result + 'DynamicBackColor' ,  __MVGET ( PreviousValue + 'DynamicBackColor' ) )
						__MVXRELEASE( PreviousValue + 'DynamicBackColor' )

						__MVPUBLIC ( Result + 'DynamicForeColor' ) 
						__MVPUT( Result + 'DynamicForeColor' ,  __MVGET ( PreviousValue + 'DynamicForeColor' ) )
						__MVXRELEASE( PreviousValue + 'DynamicForeColor' )

						__MVPUBLIC ( Result + 'ColumnWhen' ) 
						__MVPUT( Result + 'ColumnWhen' ,  __MVGET ( PreviousValue + 'ColumnWhen' ) )
						__MVXRELEASE( PreviousValue + 'ColumnWhen' )

						__MVPUBLIC ( Result + 'ColumnValid' ) 
						__MVPUT( Result + 'ColumnValid' ,  __MVGET ( PreviousValue + 'ColumnValid' ) )
						__MVXRELEASE( PreviousValue + 'ColumnValid' )

						__MVPUBLIC ( Result + 'ColumnControls' ) 
						__MVPUT( Result + 'ColumnControls' ,  __MVGET ( PreviousValue + 'ColumnControls' ) )
						__MVXRELEASE( PreviousValue + 'ColumnControls' )

						__MVPUBLIC ( Result + 'ShowHeaders' ) 
						__MVPUT( Result + 'ShowHeaders' ,  __MVGET ( PreviousValue + 'ShowHeaders' ) )
						__MVXRELEASE( PreviousValue + 'ShowHeaders' )

						__MVPUBLIC ( Result + 'HeaderImages' ) 
						__MVPUT( Result + 'HeaderImages' ,  __MVGET ( PreviousValue + 'HeaderImages' ) )
						__MVXRELEASE( PreviousValue + 'HeaderImages' )

						__MVPUBLIC ( Result + 'CellNavigation' ) 
						__MVPUT( Result + 'CellNavigation' ,  __MVGET ( PreviousValue + 'CellNavigation' ) )
						__MVXRELEASE( PreviousValue + 'CellNavigation' )




						__MVPUBLIC ( Result + 'RowSource' ) 
						__MVPUT( Result + 'RowSource' ,  __MVGET ( PreviousValue + 'RowSource' ) )
						__MVXRELEASE( PreviousValue + 'RowSource' )

						__MVPUBLIC ( Result + 'ColumnFields' ) 
						__MVPUT( Result + 'ColumnFields' ,  __MVGET ( PreviousValue + 'ColumnFields' ) )
						__MVXRELEASE( PreviousValue + 'ColumnFields' )

						__MVPUBLIC ( Result + 'AllowAppend' ) 
						__MVPUT( Result + 'AllowAppend' ,  __MVGET ( PreviousValue + 'AllowAppend' ) )
						__MVXRELEASE( PreviousValue + 'AllowAppend' )

						__MVPUBLIC ( Result + 'AllowDelete' ) 
						__MVPUT( Result + 'AllowDelete' ,  __MVGET ( PreviousValue + 'AllowDelete' ) )
						__MVXRELEASE( PreviousValue + 'AllowDelete' )

						__MVPUBLIC ( Result + 'Buffered' ) 
						__MVPUT( Result + 'Buffered' ,  __MVGET ( PreviousValue + 'Buffered' ) )
						__MVXRELEASE( PreviousValue + 'Buffered' )

						__MVPUBLIC ( Result + 'DynamicDisplay' ) 
						__MVPUT( Result + 'DynamicDisplay' ,  __MVGET ( PreviousValue + 'DynamicDisplay' ) )
						__MVXRELEASE( PreviousValue + 'DynamicDisplay' )


						__MVPUBLIC ( Result + 'OnSave' ) 
						__MVPUT( Result + 'OnSave' ,  __MVGET ( PreviousValue + 'OnSave' ) )
						__MVXRELEASE( PreviousValue + 'OnSave' )


						__MVPUBLIC ( Result + 'LockColumns' ) 
						__MVPUT( Result + 'LockColumns' ,  __MVGET ( PreviousValue + 'LockColumns' ) )
						__MVXRELEASE( PreviousValue + 'LockColumns' )

						*

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ITEMS'
					__MVPUT( SelectedControlName + 'Items' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ROWSOURCE'
					__MVPUT( SelectedControlName + 'RowSource' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'COLUMNFIELDS'
					__MVPUT( SelectedControlName + 'ColumnFields' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ALLOWAPPEND'
					__MVPUT( SelectedControlName + 'AllowAppend' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ALLOWDELETE'
					__MVPUT( SelectedControlName + 'AllowDelete' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'BUFFERED'
					__MVPUT( SelectedControlName + 'Buffered' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'DYNAMICDISPLAY'
					__MVPUT( SelectedControlName + 'DynamicDisplay' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'CELLNAVIGATION'
					__MVPUT( SelectedControlName + 'CellNavigation' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTHS'
					__MVPUT( SelectedControlName + 'Widths' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEADERS'
					__MVPUT( SelectedControlName + 'Headers' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'MULTISELECT'
					__MVPUT( SelectedControlName + 'MultiSelect' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ALLOWEDIT'
					__MVPUT( SelectedControlName + 'AllowEdit' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VIRTUAL'
					__MVPUT( SelectedControlName + 'Virtual' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'LINES'
					__MVPUT( SelectedControlName + 'Lines' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )
					WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
					HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE GRID &SelectedControlName
						ROW RowTemp
						COL ColTemp
						WIDTH WidthTemp
						HEIGHT HeightTemp
						PARENT &DesignForm
						ON GOTFOCUS SelectControl (This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )
						HEADERS {'',''} 
						WIDTHS {60,60} 
						ITEMS { { SelectedControlName ,''} }

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'ShowHeaders' )  )) == '.T.'
							SHOWHEADERS .T.
						else
							SHOWHEADERS .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'Lines' )  )) == '.T.'
							NOLINES .F.
						else
							NOLINES .T.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER( __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

					END GRID

					ColorTmp :=__MVGET ( SelectedControlName + 'FontColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &ColorTmp )
					endif
					ColorTmp :=__MVGET ( SelectedControlName + 'BackColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &ColorTmp )
					endif

					if ! empty ( TabName )

						TabPage := GetProperty ( DesignForm , TabName , 'Value' )

						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )

						DrawGrid()

						_HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] := TabName
	
					EndIf

					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'JUSTIFY'
					__MVPUT( SelectedControlName + 'Justify' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'IMAGE'
					__MVPUT( SelectedControlName + 'Image' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ITEMCOUNT'
					__MVPUT( SelectedControlName + 'ItemCount' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'BACKCOLOR'
					__MVPUT( SelectedControlName + 'BackColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , {255,255,255} )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTCOLOR'
					__MVPUT( SelectedControlName + 'FontColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , {0,0,0} )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				*


				ElseIf PropertyName == 'LOCKCOLUMNS'
					__MVPUT( SelectedControlName + 'LOCKCOLUMNS' , Result )
					SelectControl (SelectedControlName)
				ElseIf PropertyName == 'DYNAMICBACKCOLOR'
					__MVPUT( SelectedControlName + 'DYNAMICBACKCOLOR' , Result )
					SelectControl (SelectedControlName)
				ElseIf PropertyName == 'DYNAMICFORECOLOR'
					__MVPUT( SelectedControlName + 'DYNAMICFORECOLOR' , Result )
					SelectControl (SelectedControlName)
				ElseIf PropertyName == 'COLUMNWHEN'
					__MVPUT( SelectedControlName + 'COLUMNWHEN' , Result )
					SelectControl (SelectedControlName)
				ElseIf PropertyName == 'COLUMNVALID'
					__MVPUT( SelectedControlName + 'COLUMNVALID' , Result )
					SelectControl (SelectedControlName)
				ElseIf PropertyName == 'COLUMNCONTROLS'
					__MVPUT( SelectedControlName + 'COLUMNCONTROLS' , Result )
					SelectControl (SelectedControlName)
				ElseIf PropertyName == 'SHOWHEADERS'

					__MVPUT( SelectedControlName + 'SHOWHEADERS' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )
					WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
					HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE GRID &SelectedControlName
						ROW RowTemp
						COL ColTemp
						WIDTH WidthTemp
						HEIGHT HeightTemp
						PARENT &DesignForm
						ON GOTFOCUS SelectControl (This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )
						HEADERS {'',''} 
						WIDTHS {60,60} 
						ITEMS { { SelectedControlName ,''} }

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'ShowHeaders' )  )) == '.T.'
							SHOWHEADERS .T.
						else
							SHOWHEADERS .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'Lines' )  )) == '.T.'
							NOLINES .F.
						else
							NOLINES .T.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER( __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

					END GRID

					ColorTmp :=__MVGET ( SelectedControlName + 'FontColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &ColorTmp )
					endif
					ColorTmp :=__MVGET ( SelectedControlName + 'BackColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &ColorTmp )
					endif

					if ! empty ( TabName )

						TabPage := GetProperty ( DesignForm , TabName , 'Value' )

						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )

						DrawGrid()

						_HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] := TabName
	
					EndIf

					SelectControl (SelectedControlName)

                                *

				ElseIf PropertyName == 'HEADERIMAGES'
					__MVPUT( SelectedControlName + 'HEADERIMAGES' , Result )
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'SLIDER'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						__MVPUBLIC ( Result + 'RangeMin' ) 
						__MVPUT( Result + 'RangeMin' ,  __MVGET ( PreviousValue + 'RangeMin' ) )
						__MVXRELEASE( PreviousValue + 'RangeMin' )

						__MVPUBLIC ( Result + 'RangeMax' ) 
						__MVPUT( Result + 'RangeMax' ,  __MVGET ( PreviousValue + 'RangeMax' ) )
						__MVXRELEASE( PreviousValue + 'RangeMax' )

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'OnChange' ) 
						__MVPUT( Result + 'OnChange' ,  __MVGET ( PreviousValue + 'OnChange' ) )
						__MVXRELEASE( PreviousValue + 'OnChange' )

						__MVPUBLIC ( Result + 'TabStop' ) 
						__MVPUT( Result + 'TabStop' ,  __MVGET ( PreviousValue + 'TabStop' ) )
						__MVXRELEASE( PreviousValue + 'TabStop' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' ,  __MVGET ( PreviousValue + 'Visible' ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'TickMarks' ) 
						__MVPUT( Result + 'TickMarks' ,  __MVGET ( PreviousValue + 'TickMarks' ) )
						__MVXRELEASE( PreviousValue + 'TickMarks' )

						__MVPUBLIC ( Result + 'Orientation' ) 
						__MVPUT( Result + 'Orientation' ,  __MVGET ( PreviousValue + 'Orientation' ) )
						__MVXRELEASE( PreviousValue + 'Orientation' )

						__MVPUBLIC ( Result + 'BackColor' ) 
						__MVPUT( Result + 'BackColor' ,  __MVGET ( PreviousValue + 'BackColor' ) )
						__MVXRELEASE( PreviousValue + 'BackColor' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'RANGEMAX'
					__MVPUT( SelectedControlName + 'RangeMax' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'RANGEMIN'
					__MVPUT( SelectedControlName + 'RangeMin' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TABSTOP'
					__MVPUT( SelectedControlName + 'TabStop' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ORIENTATION'

					If 	( HMG_UPPER ( ALLTRIM ( __MVGET( SelectedControlName + 'Orientation' ) ) ) == 'VERTICAL' ;
						.and. ;
						HMG_UPPER ( ALLTRIM ( Result ) ) == 'HORIZONTAL' ) 

						HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
						WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )

						If HMG_UPPER ( ALLTRIM ( __MVGET ( SelectedControlName + 'TickMarks' ) ) ) == 'RIGHT'
							__MVPUT ( SelectedControlName + 'TickMarks' , 'TOP' )
						EndIf

						If HMG_UPPER ( ALLTRIM ( __MVGET ( SelectedControlName + 'TickMarks' ) ) ) == 'LEFT'
							__MVPUT ( SelectedControlName + 'TickMarks' , 'BOTTOM' )
						EndIf

					ElseIf 	( HMG_UPPER ( ALLTRIM ( __MVGET( SelectedControlName + 'Orientation' ) ) ) == 'HORIZONTAL' ;
						.and. ;
						HMG_UPPER ( ALLTRIM ( Result ) ) == 'VERTICAL' ) 

						HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
						WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )

						If HMG_UPPER ( ALLTRIM ( __MVGET ( SelectedControlName + 'TickMarks' ) ) ) == 'BOTTOM'
							__MVPUT ( SelectedControlName + 'TickMarks' , 'RIGHT' )
						EndIf

						If HMG_UPPER ( ALLTRIM ( __MVGET ( SelectedControlName + 'TickMarks' ) ) ) == 'TOP'
							__MVPUT ( SelectedControlName + 'TickMarks' , 'LEFT' )
						EndIf

					Else

						WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
						HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )

					EndIf

					__MVPUT( SelectedControlName + 'Orientation' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )

					TabName := _HMG_SYSDATA [ 36 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					if ! empty ( TabName )
						fmb := _HMG_SYSDATA [ 183 ]
						_HMG_SYSDATA [ 183 ] := 1
						_HMG_SYSDATA [ 225 ]  := TabName
						_HMG_SYSDATA [ 332 ] [_HMG_SYSDATA [ 183 ]] := DesignForm
					endif

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE SLIDER &SelectedControlName
						ROW RowTemp
						COL ColTemp
						WIDTH WidthTemp
						HEIGHT HeightTemp
						PARENT &DesignForm
						ON CHANGE SelectControl (This.Name)
						RANGEMIN 1
						RANGEMAX 10 
			
						If HMG_UPPER ( ALLTRIM ( __MVGET( SelectedControlName + 'Orientation' ) ) ) == 'VERTICAL'
							VERTICAL .T.
						EndIf

						If HMG_UPPER ( ALLTRIM ( __MVGET( SelectedControlName + 'TickMarks' ) ) ) == 'BOTH'
							BOTH .T.
						ElseIf HMG_UPPER ( ALLTRIM ( __MVGET( SelectedControlName + 'TickMarks' ) ) ) == 'LEFT'
							LEFT .T.
						ElseIf HMG_UPPER ( ALLTRIM ( __MVGET( SelectedControlName + 'TickMarks' ) ) ) == 'TOP'
							TOP .T.
						ElseIf HMG_UPPER ( ALLTRIM ( __MVGET( SelectedControlName + 'TickMarks' ) ) ) == 'NONE'
							NOTICKS .T.
						EndIf

					END SLIDER

					if ! empty ( TabName )
						_HMG_SYSDATA [ 183 ] := fmb
					endif

					ColorTmp :=__MVGET ( SelectedControlName + 'BackColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &ColorTmp )
					endif

					if ! empty ( TabName )

						TabPage := GetProperty ( DesignForm , TabName , 'Value' )

						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )

						DrawGrid()
	
					EndIf

					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)
					DrawGrid()

					SetFocus ( GetControlhandle ( SelectedControlName , DesignForm ) )

				ElseIf PropertyName == 'TICKMARKS'

					__MVPUT( SelectedControlName + 'TickMarks' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )
					WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
					HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )

					TabName := _HMG_SYSDATA [ 36 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					if ! empty ( TabName )
						fmb := _HMG_SYSDATA [ 183 ]
						_HMG_SYSDATA [ 183 ] := 1
						_HMG_SYSDATA [ 225 ]  := TabName
						_HMG_SYSDATA [ 332 ] [_HMG_SYSDATA [ 183 ]] := DesignForm
					endif

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE SLIDER &SelectedControlName
						ROW RowTemp
						COL ColTemp
						WIDTH WidthTemp
						HEIGHT HeightTemp
						PARENT &DesignForm
						ON CHANGE SelectControl (This.Name)
						RANGEMIN 1
						RANGEMAX 10 
			
						If HMG_UPPER ( ALLTRIM ( __MVGET( SelectedControlName + 'Orientation' ) ) ) == 'VERTICAL'
							VERTICAL .T.
						EndIf

						If HMG_UPPER ( ALLTRIM ( __MVGET( SelectedControlName + 'TickMarks' ) ) ) == 'BOTH'
							BOTH .T.
						ElseIf HMG_UPPER ( ALLTRIM ( __MVGET( SelectedControlName + 'TickMarks' ) ) ) == 'LEFT'
							LEFT .T.
						ElseIf HMG_UPPER ( ALLTRIM ( __MVGET( SelectedControlName + 'TickMarks' ) ) ) == 'TOP'
							TOP .T.
						ElseIf HMG_UPPER ( ALLTRIM ( __MVGET( SelectedControlName + 'TickMarks' ) ) ) == 'NONE'
							NOTICKS .T.
						EndIf

					END SLIDER

					if ! empty ( TabName )
						_HMG_SYSDATA [ 183 ] := fmb
					endif

					ColorTmp :=__MVGET ( SelectedControlName + 'BackColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &ColorTmp )
					endif

					if ! empty ( TabName )

						TabPage := GetProperty ( DesignForm , TabName , 'Value' )

						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )

						DrawGrid()
	
					EndIf

					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)
					DrawGrid()

					SetFocus ( GetControlhandle ( SelectedControlName , DesignForm ) )

				ElseIf PropertyName == 'BACKCOLOR'
					__MVPUT( SelectedControlName + 'BackColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 14 ] [z] := Nil

						RedrawWindow ( _HMG_SYSDATA [   3 ] [z] )
						setFocus(_HMG_SYSDATA [   3 ][z])

					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'SPINNER'
			*******************************************************

				If PropertyName == 'ROW'

					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						__MVPUBLIC ( Result + 'RangeMin' ) 
						__MVPUT( Result + 'RangeMin' ,  __MVGET ( PreviousValue + 'RangeMin' ) )
						__MVXRELEASE( PreviousValue + 'RangeMin' )

						__MVPUBLIC ( Result + 'RangeMax' ) 
						__MVPUT( Result + 'RangeMax' ,  __MVGET ( PreviousValue + 'RangeMax' ) )
						__MVXRELEASE( PreviousValue + 'RangeMax' )

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'OnChange' ) 
						__MVPUT( Result + 'OnChange' ,  __MVGET ( PreviousValue + 'OnChange' ) )
						__MVXRELEASE( PreviousValue + 'OnChange' )

						__MVPUBLIC ( Result + 'OnGotFocus' ) 
						__MVPUT( Result + 'OnGotFocus' ,  __MVGET ( PreviousValue + 'OnGotFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnGotFocus' )

						__MVPUBLIC ( Result + 'OnLostFocus' ) 
						__MVPUT( Result + 'OnLostFocus' ,  __MVGET ( PreviousValue + 'OnLostFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnLostFocus' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'TabStop' ) 
						__MVPUT( Result + 'TabStop' ,  __MVGET ( PreviousValue + 'TabStop' ) )
						__MVXRELEASE( PreviousValue + 'TabStop' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' ,  __MVGET ( PreviousValue + 'Visible' ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'BackColor' ) 
						__MVPUT( Result + 'BackColor' ,  __MVGET ( PreviousValue + 'BackColor' ) )
						__MVXRELEASE( PreviousValue + 'BackColor' )

						__MVPUBLIC ( Result + 'FontColor' ) 
						__MVPUT( Result + 'FontColor' ,  __MVGET ( PreviousValue + 'FontColor' ) )
						__MVXRELEASE( PreviousValue + 'FontColor' )

						__MVPUBLIC ( Result + 'Wrap' ) 
						__MVPUT( Result + 'Wrap' ,  __MVGET ( PreviousValue + 'Wrap' ) )
						__MVXRELEASE( PreviousValue + 'Wrap' )

						__MVPUBLIC ( Result + 'ReadOnly' ) 
						__MVPUT( Result + 'ReadOnly' ,  __MVGET ( PreviousValue + 'ReadOnly' ) )
						__MVXRELEASE( PreviousValue + 'ReadOnly' )

						__MVPUBLIC ( Result + 'Increment' ) 
						__MVPUT( Result + 'Increment' ,  __MVGET ( PreviousValue + 'Increment' ) )
						__MVXRELEASE( PreviousValue + 'Increment' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'RANGEMAX'
					__MVPUT( SelectedControlName + 'RangeMax' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'RANGEMIN'
					__MVPUT( SelectedControlName + 'RangeMin' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TABSTOP'
					__MVPUT( SelectedControlName + 'TabStop' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'BACKCOLOR'
					__MVPUT( SelectedControlName + 'BackColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 14 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTCOLOR'
					__MVPUT( SelectedControlName + 'FontColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 15 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WRAP'
					__MVPUT( SelectedControlName + 'Wrap' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'READONLY'
					__MVPUT( SelectedControlName + 'ReadOnly' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'INCREMENT'
					__MVPUT( SelectedControlName + 'Increment' , Result )
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'IMAGE'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						__MVPUBLIC ( Result + 'Picture' ) 
						__MVPUT( Result + 'Picture' ,  __MVGET ( PreviousValue + 'Picture' ) )
						__MVXRELEASE( PreviousValue + 'Picture' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' ,  __MVGET ( PreviousValue + 'Visible' ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'Stretch' ) 
						__MVPUT( Result + 'Stretch' ,  __MVGET ( PreviousValue + 'Stretch' ) )
						__MVXRELEASE( PreviousValue + 'Stretch' )

						__MVPUBLIC ( Result + 'Action' ) 
						__MVPUT( Result + 'Action' ,  __MVGET ( PreviousValue + 'Action' ) )
						__MVXRELEASE( PreviousValue + 'Action' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'PICTURE'
					__MVPUT( SelectedControlName + 'Picture' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'STRETCH'
					__MVPUT( SelectedControlName + 'Stretch' , Result )
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'TREE'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						SetProperty ( DesignForm , SelectedControlName , 'Item' , 1 , Result )

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'OnChange' ) 
						__MVPUT( Result + 'OnChange' ,  __MVGET ( PreviousValue + 'OnChange' ) )
						__MVXRELEASE( PreviousValue + 'OnChange' )

						__MVPUBLIC ( Result + 'OnGotFocus' ) 
						__MVPUT( Result + 'OnGotFocus' ,  __MVGET ( PreviousValue + 'OnGotFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnGotFocus' )

						__MVPUBLIC ( Result + 'OnLostFocus' ) 
						__MVPUT( Result + 'OnLostFocus' ,  __MVGET ( PreviousValue + 'OnLostFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnLostFocus' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'OnDblClick' ) 
						__MVPUT( Result + 'OnDblClick' ,  __MVGET ( PreviousValue + 'OnDblClick' ) )
						__MVXRELEASE( PreviousValue + 'OnDblClick' )

						__MVPUBLIC ( Result + 'NodeImages' ) 
						__MVPUT( Result + 'NodeImages' ,  __MVGET ( PreviousValue + 'NodeImages' ) )
						__MVXRELEASE( PreviousValue + 'NodeImages' )

						__MVPUBLIC ( Result + 'ItemImages' ) 
						__MVPUT( Result + 'ItemImages' ,  __MVGET ( PreviousValue + 'ItemImages' ) )
						__MVXRELEASE( PreviousValue + 'ItemImages' )

						__MVPUBLIC ( Result + 'RootButton' ) 
						__MVPUT( Result + 'RootButton' ,  __MVGET ( PreviousValue + 'RootButton' ) )
						__MVXRELEASE( PreviousValue + 'RootButton' )

						__MVPUBLIC ( Result + 'ItemIds' ) 
						__MVPUT( Result + 'ItemIds' ,  __MVGET ( PreviousValue + 'ItemIds' ) )
						__MVXRELEASE( PreviousValue + 'ItemIds' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NODEIMAGES'
					__MVPUT( SelectedControlName + 'NodeImages' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ITEMIMAGES'
					__MVPUT( SelectedControlName + 'ItemImages' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ROOTBUTTON'
					__MVPUT( SelectedControlName + 'RootButton' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ITEMIDS'
					__MVPUT( SelectedControlName + 'ItemIds' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'DATEPICKER'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'OnChange' ) 
						__MVPUT( Result + 'OnChange' ,  __MVGET ( PreviousValue + 'OnChange' ) )
						__MVXRELEASE( PreviousValue + 'OnChange' )

						__MVPUBLIC ( Result + 'OnGotFocus' ) 
						__MVPUT( Result + 'OnGotFocus' ,  __MVGET ( PreviousValue + 'OnGotFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnGotFocus' )

						__MVPUBLIC ( Result + 'OnLostFocus' ) 
						__MVPUT( Result + 'OnLostFocus' ,  __MVGET ( PreviousValue + 'OnLostFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnLostFocus' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'OnEnter' ) 
						__MVPUT( Result + 'OnEnter' ,  __MVGET ( PreviousValue + 'OnEnter' ) )
						__MVXRELEASE( PreviousValue + 'OnEnter' )

						__MVPUBLIC ( Result + 'TabStop' ) 
						__MVPUT( Result + 'TabStop' ,  __MVGET ( PreviousValue + 'TabStop' ) )
						__MVXRELEASE( PreviousValue + 'TabStop' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' ,  __MVGET ( PreviousValue + 'Visible' ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'ShowNone' ) 
						__MVPUT( Result + 'ShowNone' ,  __MVGET ( PreviousValue + 'ShowNone' ) )
						__MVXRELEASE( PreviousValue + 'ShowNone' )

						__MVPUBLIC ( Result + 'UpDown' ) 
						__MVPUT( Result + 'UpDown' ,  __MVGET ( PreviousValue + 'UpDown' ) )
						__MVXRELEASE( PreviousValue + 'UpDown' )

						__MVPUBLIC ( Result + 'RightAlign' ) 
						__MVPUT( Result + 'RightAlign' ,  __MVGET ( PreviousValue + 'RightAlign' ) )
						__MVXRELEASE( PreviousValue + 'RightAlign' )

						__MVPUBLIC ( Result + 'Field' ) 
						__MVPUT( Result + 'Field' ,  __MVGET ( PreviousValue + 'Field' ) )
						__MVXRELEASE( PreviousValue + 'Field' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TABSTOP'
					__MVPUT( SelectedControlName + 'TabStop' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'SHOWNONE'
					__MVPUT( SelectedControlName + 'ShowNone' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )
					WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
					HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE DATEPICKER &SelectedControlName
						ROW RowTemp
						COL ColTemp
						WIDTH WidthTemp
						HEIGHT HeightTemp
						PARENT &DesignForm
						ON GOTFOCUS SelectControl(This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'ShowNone' )    )) == '.T.'
							SHOWNONE .T.
						else
							SHOWNONE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'UpDown' )    )) == '.T.'
							UPDOWN .T.
						else
							UPDOWN .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'RightAlign' )    )) == '.T.'
							RIGHTALIGN .T.
						else
							RIGHTALIGN .F.
						endif

					END DATEPICKER

					if ! empty ( TabName )
						TabPage := GetProperty ( DesignForm , TabName , 'Value' )
						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )
						DrawGrid()
						_HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] := TabName
					EndIf

					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'UPDOWN'
					__MVPUT( SelectedControlName + 'UpDown' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )
					WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
					HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE DATEPICKER &SelectedControlName
						ROW RowTemp
						COL ColTemp
						WIDTH WidthTemp
						HEIGHT HeightTemp
						PARENT &DesignForm
						ON GOTFOCUS SelectControl(This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'ShowNone' )    )) == '.T.'
							SHOWNONE .T.
						else
							SHOWNONE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'UpDown' )    )) == '.T.'
							UPDOWN .T.
						else
							UPDOWN .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'RightAlign' )    )) == '.T.'
							RIGHTALIGN .T.
						else
							RIGHTALIGN .F.
						endif

					END DATEPICKER

					if ! empty ( TabName )
						TabPage := GetProperty ( DesignForm , TabName , 'Value' )
						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )
						DrawGrid()
						_HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] := TabName
					EndIf

					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'RIGHTALIGN'
					__MVPUT( SelectedControlName + 'RightAlign' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )
					WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
					HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE DATEPICKER &SelectedControlName
						ROW RowTemp
						COL ColTemp
						WIDTH WidthTemp
						HEIGHT HeightTemp
						PARENT &DesignForm
						ON GOTFOCUS SelectControl(This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'ShowNone' )    )) == '.T.'
							SHOWNONE .T.
						else
							SHOWNONE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'UpDown' )    )) == '.T.'
							UPDOWN .T.
						else
							UPDOWN .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'RightAlign' )    )) == '.T.'
							RIGHTALIGN .T.
						else
							RIGHTALIGN .F.
						endif

					END DATEPICKER

					if ! empty ( TabName )
						TabPage := GetProperty ( DesignForm , TabName , 'Value' )
						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )
						DrawGrid()
						_HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] := TabName
					EndIf

					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FIELD'
					__MVPUT( SelectedControlName + 'Field' , Result )
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'TEXTBOX'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)


				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						SetProperty ( DesignForm , SelectedControlName , 'Value' , Result )

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'OnChange' ) 
						__MVPUT( Result + 'OnChange' ,  __MVGET ( PreviousValue + 'OnChange' ) )
						__MVXRELEASE( PreviousValue + 'OnChange' )

						__MVPUBLIC ( Result + 'OnGotFocus' ) 
						__MVPUT( Result + 'OnGotFocus' ,  __MVGET ( PreviousValue + 'OnGotFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnGotFocus' )

						__MVPUBLIC ( Result + 'OnLostFocus' ) 
						__MVPUT( Result + 'OnLostFocus' ,  __MVGET ( PreviousValue + 'OnLostFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnLostFocus' )

						__MVPUBLIC ( Result + 'InputMask' ) 
						__MVPUT( Result + 'InputMask' ,  __MVGET ( PreviousValue + 'InputMask' ) )
						__MVXRELEASE( PreviousValue + 'InputMask' )

						__MVPUBLIC ( Result + 'Format' ) 
						__MVPUT( Result + 'Format' ,  __MVGET ( PreviousValue + 'Format' ) )
						__MVXRELEASE( PreviousValue + 'Format' )

						__MVPUBLIC ( Result + 'DataType' ) 
						__MVPUT( Result + 'DataType' ,  __MVGET ( PreviousValue + 'DataType' ) )
						__MVXRELEASE( PreviousValue + 'DataType' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'OnEnter' ) 
						__MVPUT( Result + 'OnEnter' ,  __MVGET ( PreviousValue + 'OnEnter' ) )
						__MVXRELEASE( PreviousValue + 'OnEnter' )

						__MVPUBLIC ( Result + 'Field' ) 
						__MVPUT( Result + 'Field' ,  __MVGET ( PreviousValue + 'Field' ) )
						__MVXRELEASE( PreviousValue + 'Field' )

						__MVPUBLIC ( Result + 'BackColor' ) 
						__MVPUT( Result + 'BackColor' ,  __MVGET ( PreviousValue + 'BackColor' ) )
						__MVXRELEASE( PreviousValue + 'BackColor' )

						__MVPUBLIC ( Result + 'FontColor' ) 
						__MVPUT( Result + 'FontColor' ,  __MVGET ( PreviousValue + 'FontColor' ) )
						__MVXRELEASE( PreviousValue + 'FontColor' )

						__MVPUBLIC ( Result + 'TabStop' ) 
						__MVPUT( Result + 'TabStop' ,  __MVGET ( PreviousValue + 'TabStop' ) )
						__MVXRELEASE( PreviousValue + 'TabStop' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' ,  __MVGET ( PreviousValue + 'Visible' ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'ReadOnly' ) 
						__MVPUT( Result + 'ReadOnly' ,  __MVGET ( PreviousValue + 'ReadOnly' ) )
						__MVXRELEASE( PreviousValue + 'ReadOnly' )

						__MVPUBLIC ( Result + 'RightAlign' ) 
						__MVPUT( Result + 'RightAlign' ,  __MVGET ( PreviousValue + 'RightAlign' ) )
						__MVXRELEASE( PreviousValue + 'RightAlign' )

						__MVPUBLIC ( Result + 'MaxLength' ) 
						__MVPUT( Result + 'MaxLength' ,  __MVGET ( PreviousValue + 'MaxLength' ) )
						__MVXRELEASE( PreviousValue + 'MaxLength' )

						__MVPUBLIC ( Result + 'Password' ) 
						__MVPUT( Result + 'Password' ,  __MVGET ( PreviousValue + 'Password' ) )
						__MVXRELEASE( PreviousValue + 'Password' )

						__MVPUBLIC ( Result + 'CaseConvert' ) 
						__MVPUT( Result + 'CaseConvert' ,  __MVGET ( PreviousValue + 'CaseConvert' ) )
						__MVXRELEASE( PreviousValue + 'CaseConvert' )

						__MVPUBLIC ( Result + 'DisabledBackColor' ) 
						__MVPUT( Result + 'DisabledBackColor' ,  __MVGET ( PreviousValue + 'DisabledBackColor' ) )
						__MVXRELEASE( PreviousValue + 'DisabledBackColor' )

						__MVPUBLIC ( Result + 'DisabledFontColor' ) 
						__MVPUT( Result + 'DisabledFontColor' ,  __MVGET ( PreviousValue + 'DisabledFontColor' ) )
						__MVXRELEASE( PreviousValue + 'DisabledFontColor' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'INPUTMASK'
					__MVPUT( SelectedControlName + 'InputMask' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FORMAT'
					__MVPUT( SelectedControlName + 'Format' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'DATATYPE'
					__MVPUT( SelectedControlName + 'DataType' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FIELD'
					__MVPUT( SelectedControlName + 'Field' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'BACKCOLOR'
					__MVPUT( SelectedControlName + 'BackColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 14 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTCOLOR'
					__MVPUT( SelectedControlName + 'FontColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 15 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TABSTOP'
					__MVPUT( SelectedControlName + 'TabStop' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'READONLY'
					__MVPUT( SelectedControlName + 'ReadOnly' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'RIGHTALIGN'
					__MVPUT( SelectedControlName + 'RightAlign' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )
					WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
					HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					DoMethod ( DesignForm , SelectedControlName , 'Release' )
	
					DEFINE TEXTBOX &SelectedControlName
						ROW RowTemp
						COL ColTemp
						WIDTH WidthTemp
						HEIGHT HeightTemp
						PARENT &DesignForm
						ON GOTFOCUS SelectControl(This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )

						VALUE SelectedControlName

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'RightAlign' )    )) == '.T.'
							RIGHTALIGN .T.
						endif

					END TEXTBOX

					ColorTmp :=__MVGET ( SelectedControlName + 'BackColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &ColorTmp )
					endif
					ColorTmp :=__MVGET ( SelectedControlName + 'FontColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &ColorTmp )
					endif

					if ! empty ( TabName )
						TabPage := GetProperty ( DesignForm , TabName , 'Value' )
						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )
						DrawGrid()
						_HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] := TabName
					EndIf

					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'MAXLENGTH'
					__MVPUT( SelectedControlName + 'MaxLength' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'PASSWORD'
					__MVPUT( SelectedControlName + 'Password' , Result )
					SelectControl (SelectedControlName)

					ElseIf PropertyName == 'DISABLEDFONTCOLOR'
						__MVPUT( SelectedControlName + 'DisabledFontColor' , Result )
						SelectControl (SelectedControlName)

					ElseIf PropertyName == 'DISABLEDBACKCOLOR'
						__MVPUT( SelectedControlName + 'DisabledBackColor' , Result )
						SelectControl (SelectedControlName)

					ElseIf PropertyName == 'CASECONVERT'
						__MVPUT( SelectedControlName + 'CaseConvert' , Result )
						SelectControl (SelectedControlName)
						
				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'EDITBOX'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						SetProperty ( DesignForm , SelectedControlName , 'Value' , Result )

						__MVPUBLIC ( Result + 'ReadOnly' ) 
						__MVPUT( Result + 'ReadOnly' ,  __MVGET ( PreviousValue + 'ReadOnly' ) )
						__MVXRELEASE( PreviousValue + 'ReadOnly' )

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'OnChange' ) 
						__MVPUT( Result + 'OnChange' ,  __MVGET ( PreviousValue + 'OnChange' ) )
						__MVXRELEASE( PreviousValue + 'OnChange' )

						__MVPUBLIC ( Result + 'OnGotFocus' ) 
						__MVPUT( Result + 'OnGotFocus' ,  __MVGET ( PreviousValue + 'OnGotFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnGotFocus' )

						__MVPUBLIC ( Result + 'OnLostFocus' ) 
						__MVPUT( Result + 'OnLostFocus' ,  __MVGET ( PreviousValue + 'OnLostFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnLostFocus' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'BackColor' ) 
						__MVPUT( Result + 'BackColor' ,  __MVGET ( PreviousValue + 'BackColor' ) )
						__MVXRELEASE( PreviousValue + 'BackColor' )

						__MVPUBLIC ( Result + 'FontColor' ) 
						__MVPUT( Result + 'FontColor' ,  __MVGET ( PreviousValue + 'FontColor' ) )
						__MVXRELEASE( PreviousValue + 'FontColor' )

						__MVPUBLIC ( Result + 'TabStop' ) 
						__MVPUT( Result + 'TabStop' ,  __MVGET ( PreviousValue + 'TabStop' ) )
						__MVXRELEASE( PreviousValue + 'TabStop' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' ,  __MVGET ( PreviousValue + 'Visible' ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'Field' ) 
						__MVPUT( Result + 'Field' ,  __MVGET ( PreviousValue + 'Field' ) )
						__MVXRELEASE( PreviousValue + 'Field' )

						__MVPUBLIC ( Result + 'MaxLength' ) 
						__MVPUT( Result + 'MaxLength' ,  __MVGET ( PreviousValue + 'MaxLength' ) )
						__MVXRELEASE( PreviousValue + 'MaxLength' )

						__MVPUBLIC ( Result + 'vScrollBar' ) 
						__MVPUT( Result + 'vScrollBar' ,  __MVGET ( PreviousValue + 'vScrollBar' ) )
						__MVXRELEASE( PreviousValue + 'vScrollBar' )

						__MVPUBLIC ( Result + 'hScrollBar' ) 
						__MVPUT( Result + 'hScrollBar' ,  __MVGET ( PreviousValue + 'hScrollBar' ) )
						__MVXRELEASE( PreviousValue + 'hScrollBar' )

						__MVPUBLIC ( Result + 'DisabledBackColor' ) 
						__MVPUT( Result + 'DisabledBackColor' ,  __MVGET ( PreviousValue + 'DisabledBackColor' ) )
						__MVXRELEASE( PreviousValue + 'DisabledBackColor' )

						__MVPUBLIC ( Result + 'DisabledFontColor' ) 
						__MVPUT( Result + 'DisabledFontColor' ,  __MVGET ( PreviousValue + 'DisabledFontColor' ) )
						__MVXRELEASE( PreviousValue + 'DisabledFontColor' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'READONLY'
					__MVPUT( SelectedControlName + 'ReadOnly' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'BACKCOLOR'
					__MVPUT( SelectedControlName + 'BackColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 14 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTCOLOR'
					__MVPUT( SelectedControlName + 'FontColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 15 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TABSTOP'
					__MVPUT( SelectedControlName + 'TabStop' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'MAXLENGTH'
					__MVPUT( SelectedControlName + 'MaxLength' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FIELD'
					__MVPUT( SelectedControlName + 'Field' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'DISABLEDBACKCOLOR'
					__MVPUT( SelectedControlName + 'DisabledBackColor' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'DISABLEDFONTCOLOR'
					__MVPUT( SelectedControlName + 'DisabledFontColor' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VSCROLLBAR'

					__MVPUT( SelectedControlName + 'vScrollBar' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )
					WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
					HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE EDITBOX &SelectedControlName
						ROW RowTemp
						COL ColTemp
						PARENT &DesignForm
						VALUE SelectedControlName

						ON GOTFOCUS SelectControl (This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )
						WIDTH WidthTemp
						HEIGHT HeightTemp

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'hScrollBar' )  )) == '.T.'
							HSCROLLBAR .T.
						else
							HSCROLLBAR .F.
						endif
						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'vScrollBar' )  )) == '.T.'
							VSCROLLBAR .T.
						else
							VSCROLLBAR .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

					END EDITBOX

					ColorTmp :=__MVGET ( SelectedControlName + 'FontColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &ColorTmp )
					endif
					ColorTmp :=__MVGET ( SelectedControlName + 'BackColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &ColorTmp )
					endif

					if ! empty ( TabName )

						TabPage := GetProperty ( DesignForm , TabName , 'Value' )

						TabRow	:= GetProperty ( DesignForm , TabName , 'Row' )
						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )

						* MiniGUI Bug!!!!
						SetProperty ( DesignForm , TabName , 'Row' , TabRow )

						_HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )]  := TabName
	
					EndIf

					Redrawwindow(DesignFormHandle)
					DrawGrid()
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HSCROLLBAR'

					__MVPUT( SelectedControlName + 'hScrollBar' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )
					WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
					HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE EDITBOX &SelectedControlName
						ROW RowTemp
						COL ColTemp
						PARENT &DesignForm
						VALUE SelectedControlName

						ON GOTFOCUS SelectControl (This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )
						WIDTH WidthTemp
						HEIGHT HeightTemp

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'hScrollBar' )  )) == '.T.'
							HSCROLLBAR .T.
						else
							HSCROLLBAR .F.
						endif
						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'vScrollBar' )  )) == '.T.'
							VSCROLLBAR .T.
						else
							VSCROLLBAR .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

					END EDITBOX

					ColorTmp :=__MVGET ( SelectedControlName + 'FontColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &ColorTmp )
					endif
					ColorTmp :=__MVGET ( SelectedControlName + 'BackColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &ColorTmp )
					endif

					if ! empty ( TabName )

						TabPage := GetProperty ( DesignForm , TabName , 'Value' )

						TabRow	:= GetProperty ( DesignForm , TabName , 'Row' )
						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )

						* MiniGUI Bug!!!!
						SetProperty ( DesignForm , TabName , 'Row' , TabRow )

						_HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] := TabName
	
					EndIf

					Redrawwindow(DesignFormHandle)
					DrawGrid()
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'LABEL'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'BackColor' ) 
						__MVPUT( Result + 'BackColor' ,  __MVGET ( PreviousValue + 'BackColor' ) )
						__MVXRELEASE( PreviousValue + 'BackColor' )

						__MVPUBLIC ( Result + 'FontColor' ) 
						__MVPUT( Result + 'FontColor' ,  __MVGET ( PreviousValue + 'FontColor' ) )
						__MVXRELEASE( PreviousValue + 'FontColor' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' ,  __MVGET ( PreviousValue + 'Visible' ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'Transparent' ) 
						__MVPUT( Result + 'Transparent' ,  __MVGET ( PreviousValue + 'Transparent' ) )
						__MVXRELEASE( PreviousValue + 'Transparent' )

						__MVPUBLIC ( Result + 'Action' ) 
						__MVPUT( Result + 'Action' ,  __MVGET ( PreviousValue + 'Action' ) )
						__MVXRELEASE( PreviousValue + 'Action' )

						__MVPUBLIC ( Result + 'AutoSize' ) 
						__MVPUT( Result + 'AutoSize' ,  __MVGET ( PreviousValue + 'AutoSize' ) )
						__MVXRELEASE( PreviousValue + 'AutoSize' )

						__MVPUBLIC ( Result + 'Alignment' ) 
						__MVPUT( Result + 'Alignment' ,  __MVGET ( PreviousValue + 'Alignment' ) )
						__MVXRELEASE( PreviousValue + 'Alignment' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'BACKCOLOR'
					__MVPUT( SelectedControlName + 'BackColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 14 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif

					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTCOLOR'
					__MVPUT( SelectedControlName + 'FontColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 15 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TRANSPARENT'
					__MVPUT( SelectedControlName + 'Transparent' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'AUTOSIZE'
					__MVPUT( SelectedControlName + 'AutoSize' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ALIGNMENT'
					__MVPUT( SelectedControlName + 'Alignment' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )
					WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
					HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE LABEL &SelectedControlName
						ROW RowTemp
						COL ColTemp
						WIDTH WidthTemp
						HEIGHT HeightTemp
						PARENT &DesignForm
						ACTION SelectControl(This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )

						VALUE __MVGET ( SelectedControlName + 'Value' )

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'Alignment' )    )) == 'CENTER'
							CENTERALIGN .T.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'Alignment' )    )) == 'RIGHT'
							RIGHTALIGN .T.
						endif

						if ( ! Empty ( TabName ) ) .AND. IsAppThemed()
							TRANSPARENT .T.
						endif

					END LABEL

					ColorTmp :=__MVGET ( SelectedControlName + 'BackColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &ColorTmp )
					endif
					ColorTmp :=__MVGET ( SelectedControlName + 'FontColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &ColorTmp )
					endif

					if ! empty ( TabName )
						TabPage := GetProperty ( DesignForm , TabName , 'Value' )
						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )
						DrawGrid()
						_HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] := TabName
					EndIf

					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'BROWSE'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						SetProperty ( DesignForm , SelectedControlName , 'Header' , 1 ,  Result )

						__MVPUBLIC ( Result + 'WorkArea' ) 
						__MVPUT( Result + 'WorkArea' ,  __MVGET ( PreviousValue + 'WorkArea' ) )
						__MVXRELEASE( PreviousValue + 'WorkArea' )

						__MVPUBLIC ( Result + 'Fields' ) 
						__MVPUT( Result + 'Fields' ,  __MVGET ( PreviousValue + 'Fields' ) )
						__MVXRELEASE( PreviousValue + 'Fields' )

						__MVPUBLIC ( Result + 'Headers' ) 
						__MVPUT( Result + 'Headers' ,  __MVGET ( PreviousValue + 'Headers' ) )
						__MVXRELEASE( PreviousValue + 'Headers' )

						__MVPUBLIC ( Result + 'Widths' ) 
						__MVPUT( Result + 'Widths' ,  __MVGET ( PreviousValue + 'Widths' ) )
						__MVXRELEASE( PreviousValue + 'Widths' )

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'OnChange' ) 
						__MVPUT( Result + 'OnChange' ,  __MVGET ( PreviousValue + 'OnChange' ) )
						__MVXRELEASE( PreviousValue + 'OnChange' )

						__MVPUBLIC ( Result + 'OnGotFocus' ) 
						__MVPUT( Result + 'OnGotFocus' ,  __MVGET ( PreviousValue + 'OnGotFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnGotFocus' )

						__MVPUBLIC ( Result + 'OnLostFocus' ) 
						__MVPUT( Result + 'OnLostFocus' ,  __MVGET ( PreviousValue + 'OnLostFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnLostFocus' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'BackColor' ) 
						__MVPUT( Result + 'BackColor' ,  __MVGET ( PreviousValue + 'BackColor' ) )
						__MVXRELEASE( PreviousValue + 'BackColor' )

						__MVPUBLIC ( Result + 'FontColor' ) 
						__MVPUT( Result + 'FontColor' ,  __MVGET ( PreviousValue + 'FontColor' ) )
						__MVXRELEASE( PreviousValue + 'FontColor' )

						__MVPUBLIC ( Result + 'OnDblClick' ) 
						__MVPUT( Result + 'OnDblClick' ,  __MVGET ( PreviousValue + 'OnDblClick' ) )
						__MVXRELEASE( PreviousValue + 'OnDblClick' )

						__MVPUBLIC ( Result + 'AllowEdit' ) 
						__MVPUT( Result + 'AllowEdit' ,  __MVGET ( PreviousValue + 'AllowEdit' ) )
						__MVXRELEASE( PreviousValue + 'AllowEdit' )

						__MVPUBLIC ( Result + 'AllowAppend' ) 
						__MVPUT( Result + 'AllowAppend' ,  __MVGET ( PreviousValue + 'AllowAppend' ) )
						__MVXRELEASE( PreviousValue + 'AllowAppend' )

						__MVPUBLIC ( Result + 'OnHeadClick' ) 
						__MVPUT( Result + 'OnHeadClick' ,  __MVGET ( PreviousValue + 'OnHeadClick' ) )
						__MVXRELEASE( PreviousValue + 'OnHeadClick' )

						__MVPUBLIC ( Result + 'AllowDelete' ) 
						__MVPUT( Result + 'AllowDelete' ,  __MVGET ( PreviousValue + 'AllowDelete' ) )
						__MVXRELEASE( PreviousValue + 'AllowDelete' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'Image' ) 
						__MVPUT( Result + 'Image' ,  __MVGET ( PreviousValue + 'Image' ) )
						__MVXRELEASE( PreviousValue + 'Image' )

						__MVPUBLIC ( Result + 'Justify' ) 
						__MVPUT( Result + 'Justify' ,  __MVGET ( PreviousValue + 'Justify' ) )
						__MVXRELEASE( PreviousValue + 'Justify' )

						__MVPUBLIC ( Result + 'Lines' ) 
						__MVPUT( Result + 'Lines' ,  __MVGET ( PreviousValue + 'Lines' ) )
						__MVXRELEASE( PreviousValue + 'Lines' )

						__MVPUBLIC ( Result + 'ReadOnlyFields' ) 
						__MVPUT( Result + 'ReadOnlyFields' ,  __MVGET ( PreviousValue + 'ReadOnlyFields' ) )
						__MVXRELEASE( PreviousValue + 'ReadOnlyFields' )

						__MVPUBLIC ( Result + 'Valid' ) 
						__MVPUT( Result + 'Valid' ,  __MVGET ( PreviousValue + 'Valid' ) )
						__MVXRELEASE( PreviousValue + 'Valid' )

						__MVPUBLIC ( Result + 'ValidMessages' ) 
						__MVPUT( Result + 'ValidMessages' ,  __MVGET ( PreviousValue + 'ValidMessages' ) )
						__MVXRELEASE( PreviousValue + 'ValidMessages' )

						__MVPUBLIC ( Result + 'Lock' ) 
						__MVPUT( Result + 'Lock' ,  __MVGET ( PreviousValue + 'Lock' ) )
						__MVXRELEASE( PreviousValue + 'Lock' )

						__MVPUBLIC ( Result + 'vScrollBar' ) 
						__MVPUT( Result + 'vScrollBar' ,  __MVGET ( PreviousValue + 'vScrollBar' ) )
						__MVXRELEASE( PreviousValue + 'vScrollBar' )

						__MVPUBLIC ( Result + 'DynamicBackColor' ) 
						__MVPUT( Result + 'DynamicBackColor' ,  __MVGET ( PreviousValue + 'DynamicBackColor' ) )
						__MVXRELEASE( PreviousValue + 'DynamicBackColor' )

						__MVPUBLIC ( Result + 'DynamicForeColor' ) 
						__MVPUT( Result + 'DynamicForeColor' ,  __MVGET ( PreviousValue + 'DynamicForeColor' ) )
						__MVXRELEASE( PreviousValue + 'DynamicForeColor' )

						__MVPUBLIC ( Result + 'InputMask' ) 
						__MVPUT( Result + 'InputMask' ,  __MVGET ( PreviousValue + 'InputMask' ) )
						__MVXRELEASE( PreviousValue + 'InputMask' )

						__MVPUBLIC ( Result + 'Format' ) 
						__MVPUT( Result + 'Format' ,  __MVGET ( PreviousValue + 'Format' ) )
						__MVXRELEASE( PreviousValue + 'Format' )

						__MVPUBLIC ( Result + 'When' ) 
						__MVPUT( Result + 'When' ,  __MVGET ( PreviousValue + 'When' ) )
						__MVXRELEASE( PreviousValue + 'When' )

						__MVPUBLIC ( Result + 'DisplayItems' ) 
						__MVPUT( Result + 'DisplayItems' ,  __MVGET ( PreviousValue + 'DisplayItems' ) )
						__MVXRELEASE( PreviousValue + 'DisplayItems' )

						__MVPUBLIC ( Result + 'HeaderImages' ) 
						__MVPUT( Result + 'HeaderImages' ,  __MVGET ( PreviousValue + 'HeaderImages' ) )
						__MVXRELEASE( PreviousValue + 'HeaderImages' )

						__MVPUBLIC ( Result + 'InputItems' ) 
						__MVPUT( Result + 'InputItems' ,  __MVGET ( PreviousValue + 'InputItems' ) )
						__MVXRELEASE( PreviousValue + 'InputItems' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTHS'
					__MVPUT( SelectedControlName + 'Widths' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FIELDS'
					__MVPUT( SelectedControlName + 'Fields' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WORKAREA'
					__MVPUT( SelectedControlName + 'WorkArea' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEADERS'
					__MVPUT( SelectedControlName + 'Headers' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'BACKCOLOR'

					
					__MVPUT( SelectedControlName + 'BackColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)

						nTemp := GetControlSysColor()
						z := GetControlIndex ( SelectedControlName , DesignForm )
						ListView_SetBkColor ( _HMG_SYSDATA [   3 ] [z] , GetRed(nTemp) , GetGreen(nTemp) , GetBlue(nTemp) )
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )

					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTCOLOR'
					__MVPUT( SelectedControlName + 'FontColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 15 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ALLOWEDIT'
					__MVPUT( SelectedControlName + 'AllowEdit' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ALLOWAPPEND'
					__MVPUT( SelectedControlName + 'AllowAppend' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ALLOWDELETE'
					__MVPUT( SelectedControlName + 'AllowDelete' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'JUSTIFY'
					__MVPUT( SelectedControlName + 'Justify' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'IMAGE'
					__MVPUT( SelectedControlName + 'Image' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'LINES'
					__MVPUT( SelectedControlName + 'Lines' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )
					WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
					HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )

					TabName := _HMG_SYSDATA [ 37 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE BROWSE &SelectedControlName
						ROW RowTemp
						COL ColTemp
						WIDTH WidthTemp
						HEIGHT HeightTemp
						PARENT &DesignForm
						ON GOTFOCUS SelectControl (This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )
						HEADERS { SelectedControlName } 
						WIDTHS { 100 } 
						WORKAREA Test 
						FIELDS { 'Test->Code' } 
						VALUE 1
						VSCROLLBAR .F.
                                                						
						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'Lines' )  )) == '.T.'
							NOLINES .F.
						else
							NOLINES .T.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER( __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

					END BROWSE

					ColorTmp :=__MVGET ( SelectedControlName + 'FontColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &ColorTmp )
					endif
					ColorTmp :=__MVGET ( SelectedControlName + 'BackColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &ColorTmp )
					endif

					if ! empty ( TabName )

						TabPage := GetProperty ( DesignForm , TabName , 'Value' )

						TabRow	:= GetProperty ( DesignForm , TabName , 'Row' )
						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )

						* MiniGUI Bug!!!!
						SetProperty ( DesignForm , TabName , 'Row' , TabRow )

						_HMG_SYSDATA [ 37 ] [GetControlIndex ( SelectedControlName , DesignForm )] := TabName
	
					EndIf

					Redrawwindow(DesignFormHandle)
					DrawGrid()
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'READONLYFIELDS'
					__MVPUT( SelectedControlName + 'ReadOnlyFields' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALID'
					__MVPUT( SelectedControlName + 'Valid' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALIDMESSAGES'
					__MVPUT( SelectedControlName + 'ValidMessages' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'LOCK'
					__MVPUT( SelectedControlName + 'Lock' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VSCROLLBAR'
					__MVPUT( SelectedControlName + 'vScrollBar' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'DYNAMICBACKCOLOR'
					__MVPUT( SelectedControlName + 'DYNAMICBACKCOLOR' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'DYNAMICFORECOLOR'
					__MVPUT( SelectedControlName + 'DYNAMICFORECOLOR' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'INPUTMASK'
					__MVPUT( SelectedControlName + 'INPUTMASK' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FORMAT'
					__MVPUT( SelectedControlName + 'FORMAT' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WHEN'
					__MVPUT( SelectedControlName + 'WHEN' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'INPUTITEMS'
					__MVPUT( SelectedControlName + 'INPUTITEMS' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'DISPLAYITEMS'
					__MVPUT( SelectedControlName + 'DISPLAYITEMS' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEADERIMAGES'
					__MVPUT( SelectedControlName + 'HEADERIMAGES' , Result )
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'RADIOGROUP'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						__MVPUBLIC ( Result + 'ReadOnly' ) 
						__MVPUT( Result + 'ReadOnly' ,  __MVGET ( PreviousValue + 'ReadOnly' ) )
						__MVXRELEASE( PreviousValue + 'ReadOnly' )

						__MVPUBLIC ( Result + 'Orientation' ) 
						__MVPUT( Result + 'Orientation' ,  __MVGET ( PreviousValue + 'Orientation' ) )
						__MVXRELEASE( PreviousValue + 'Orientation' )



						__MVPUBLIC ( Result + 'Options' ) 
						__MVPUT( Result + 'Options' ,  __MVGET ( PreviousValue + 'Options' ) )
						__MVXRELEASE( PreviousValue + 'Options' )

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'OnChange' ) 
						__MVPUT( Result + 'OnChange' ,  __MVGET ( PreviousValue + 'OnChange' ) )
						__MVXRELEASE( PreviousValue + 'OnChange' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'BackColor' ) 
						__MVPUT( Result + 'BackColor' ,  __MVGET ( PreviousValue + 'BackColor' ) )
						__MVXRELEASE( PreviousValue + 'BackColor' )

						__MVPUBLIC ( Result + 'FontColor' ) 
						__MVPUT( Result + 'FontColor' ,  __MVGET ( PreviousValue + 'FontColor' ) )
						__MVXRELEASE( PreviousValue + 'FontColor' )

						__MVPUBLIC ( Result + 'TabStop' ) 
						__MVPUT( Result + 'TabStop' ,  __MVGET ( PreviousValue + 'TabStop' ) )
						__MVXRELEASE( PreviousValue + 'TabStop' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' ,  __MVGET ( PreviousValue + 'Visible' ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'Transparent' ) 
						__MVPUT( Result + 'Transparent' ,  __MVGET ( PreviousValue + 'Transparent' ) )
						__MVXRELEASE( PreviousValue + 'Transparent' )

						__MVPUBLIC ( Result + 'Spacing' ) 
						__MVPUT( Result + 'Spacing' ,  __MVGET ( PreviousValue + 'Spacing' ) )
						__MVXRELEASE( PreviousValue + 'Spacing' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'OPTIONS'

					aTemp := StringToArray ( Result )
					if HMG_LEN ( aTemp ) == 1
						MsgStop ('Options Array Length Must Be At Least 2. Aborted','HMG IDE')
						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)
						RETURN
					Endif

					__MVPUT( SelectedControlName + 'Options' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )
					WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )

                                        				
					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					if ! empty ( TabName )
						fmb := _HMG_SYSDATA [ 183 ]
						_HMG_SYSDATA [ 183 ] := 1
						_HMG_SYSDATA [ 225 ]  := TabName
						_HMG_SYSDATA [ 332 ] [_HMG_SYSDATA [ 183 ]] := DesignForm
					endif

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE RADIOGROUP &SelectedControlName
						ROW RowTemp
						COL ColTemp
						PARENT &DesignForm
						OPTIONS aTemp
						ON CHANGE SelectControl (This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )
						SPACING VAL ( __MVGET ( SelectedControlName + 'Spacing' ) )
						WIDTH WidthTemp

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'Orientation' )  )) == 'HORIZONTAL'
							HORIZONTAL .T.
						else
							HORIZONTAL .F.
						endif


						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

					END RADIOGROUP

					if ! empty ( TabName )
						_HMG_SYSDATA [ 183 ] := fmb
					endif


					ColorTmp :=__MVGET ( SelectedControlName + 'FontColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &ColorTmp )
					endif
					ColorTmp :=__MVGET ( SelectedControlName + 'BackColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &ColorTmp )
					endif

					if ! empty ( TabName )

						TabPage := GetProperty ( DesignForm , TabName , 'Value' )

						TabRow	:= GetProperty ( DesignForm , TabName , 'Row' )
						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )

						* MiniGUI Bug!!!!
						SetProperty ( DesignForm , TabName , 'Row' , TabRow )
	
					EndIf

					Redrawwindow(DesignFormHandle)
					DrawGrid()
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'BACKCOLOR'
					__MVPUT( SelectedControlName + 'BackColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 14 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTCOLOR'
					__MVPUT( SelectedControlName + 'FontColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 15 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TABSTOP'
					__MVPUT( SelectedControlName + 'TabStop' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TRANSPARENT'
					__MVPUT( SelectedControlName + 'Transparent' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'SPACING'

					__MVPUT( SelectedControlName + 'Spacing' , Result )

					z := GetControlIndex ( SelectedControlName , DesignForm )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )
					WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
					OptTemp := _HMG_SYSDATA [ 33 ] [z]

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					if ! empty ( TabName )
						fmb := _HMG_SYSDATA [ 183 ]
						_HMG_SYSDATA [ 183 ] := 1
						_HMG_SYSDATA [ 225 ]  := TabName
						_HMG_SYSDATA [ 332 ] [_HMG_SYSDATA [ 183 ]] := DesignForm
					endif

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE RADIOGROUP &SelectedControlName
						ROW RowTemp
						COL ColTemp
						PARENT &DesignForm
						OPTIONS OptTemp
						ON CHANGE SelectControl (This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )
						SPACING VAL ( __MVGET ( SelectedControlName + 'Spacing' ) )
						WIDTH WidthTemp

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'Orientation' )  )) == 'HORIZONTAL'
							HORIZONTAL .T.
						else
							HORIZONTAL .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

					END RADIOGROUP

					if ! empty ( TabName )
						_HMG_SYSDATA [ 183 ] := fmb
					endif

					ColorTmp :=__MVGET ( SelectedControlName + 'FontColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &ColorTmp )
					endif
					ColorTmp :=__MVGET ( SelectedControlName + 'BackColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &ColorTmp )
					endif

					if ! empty ( TabName )

						TabPage := GetProperty ( DesignForm , TabName , 'Value' )

						TabRow	:= GetProperty ( DesignForm , TabName , 'Row' )
						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )

						* MiniGUI Bug!!!!
						SetProperty ( DesignForm , TabName , 'Row' , TabRow )
	
					EndIf

					Redrawwindow(DesignFormHandle)
					DrawGrid()
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'READONLY'
					__MVPUT( SelectedControlName + 'ReadOnly' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ORIENTATION'

					__MVPUT( SelectedControlName + 'Orientation' , Result )

					If result == 'VERTICAL'
						__MVPUT( SelectedControlName + 'Spacing' , '25' )
					elseif result == 'HORIZONTAL'
						__MVPUT( SelectedControlName + 'Spacing' , '125' )
					endif

					z := GetControlIndex ( SelectedControlName , DesignForm )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )
					WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
					OptTemp := _HMG_SYSDATA [ 33 ] [z]

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					if ! empty ( TabName )
						fmb := _HMG_SYSDATA [ 183 ]
						_HMG_SYSDATA [ 183 ] := 1
						_HMG_SYSDATA [ 225 ]  := TabName
						_HMG_SYSDATA [ 332 ] [_HMG_SYSDATA [ 183 ]] := DesignForm
					endif

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE RADIOGROUP &SelectedControlName
						ROW RowTemp
						COL ColTemp
						PARENT &DesignForm
						OPTIONS OptTemp
						ON CHANGE SelectControl (This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )
						SPACING VAL ( __MVGET ( SelectedControlName + 'Spacing' ) )
						WIDTH WidthTemp

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'Orientation' )  )) == 'HORIZONTAL'
							HORIZONTAL .T.
						else
							HORIZONTAL .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

					END RADIOGROUP

					if ! empty ( TabName )
						_HMG_SYSDATA [ 183 ] := fmb
					endif

					ColorTmp :=__MVGET ( SelectedControlName + 'FontColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &ColorTmp )
					endif
					ColorTmp :=__MVGET ( SelectedControlName + 'BackColor' )
					if HB_ULEFT(ALLTRIM( ColorTmp ),1) == '{' 
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &ColorTmp )
					endif

					if ! empty ( TabName )

						TabPage := GetProperty ( DesignForm , TabName , 'Value' )

						TabRow	:= GetProperty ( DesignForm , TabName , 'Row' )
						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )

						* MiniGUI Bug!!!!
						SetProperty ( DesignForm , TabName , 'Row' , TabRow )
	
					EndIf

					Redrawwindow(DesignFormHandle)
					DrawGrid()
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'FRAME'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						__MVPUBLIC ( Result + 'Caption' ) 
						__MVPUT( Result + 'Caption' ,  __MVGET ( PreviousValue + 'Caption' ) )
						__MVXRELEASE( PreviousValue + 'Caption' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'Transparent' ) 
						__MVPUT( Result + 'Transparent' ,  __MVGET ( PreviousValue + 'Transparent' ) )
						__MVXRELEASE( PreviousValue + 'Transparent' )

						__MVPUBLIC ( Result + 'BackColor' ) 
						__MVPUT( Result + 'BackColor' ,  __MVGET ( PreviousValue + 'BackColor' ) )
						__MVXRELEASE( PreviousValue + 'BackColor' )

						__MVPUBLIC ( Result + 'FontColor' ) 
						__MVPUT( Result + 'FontColor' ,  __MVGET ( PreviousValue + 'FontColor' ) )
						__MVXRELEASE( PreviousValue + 'FontColor' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'CAPTION'

					__MVPUT( SelectedControlName + 'Caption' , Result )

					if empty ( result )
						SetProperty ( DesignForm , SelectedControlName , 'fontsize' , 1 )
					else
						SetProperty ( DesignForm , SelectedControlName , 'fontsize' , VAL ( __MVGET( SelectedControlName + 'FontSize' ) ) )
					endif

					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TRANSPARENT'

					__MVPUT( SelectedControlName + 'Transparent' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'BACKCOLOR'
					__MVPUT( SelectedControlName + 'BackColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 14 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTCOLOR'
					__MVPUT( SelectedControlName + 'FontColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 15 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'TAB'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						_OLDNAME := _HMG_SYSDATA [2] [X]
						_NEWNAME := Result

						FOR Z := 1 TO HMG_LEN ( _HMG_SYSDATA [1] )

							IF _HMG_SYSDATA [1] [Z] == 'CHECKBOX' .AND. VALTYPE ( _HMG_SYSDATA [31] [Z] ) == 'C'
								IF HMG_UPPER ( ALLTRIM ( _HMG_SYSDATA [31] [Z] ) ) == HMG_UPPER ( ALLTRIM ( _OLDNAME ) )
									_HMG_SYSDATA [31] [Z] := _NEWNAME
								ENDIF
							ENDIF

							IF _HMG_SYSDATA [1] [Z] == 'SLIDER' .AND. VALTYPE ( _HMG_SYSDATA [36] [Z] ) == 'C'
								IF HMG_UPPER ( ALLTRIM ( _HMG_SYSDATA [36] [Z] ) ) == HMG_UPPER ( ALLTRIM ( _OLDNAME ) )
									_HMG_SYSDATA [36] [Z] := _NEWNAME
								ENDIF
							ENDIF

							IF _HMG_SYSDATA [1] [Z] == 'RADIOGROUP' .AND. VALTYPE ( _HMG_SYSDATA [31] [Z] ) == 'C'
								IF HMG_UPPER ( ALLTRIM ( _HMG_SYSDATA [31] [Z] ) ) == HMG_UPPER ( ALLTRIM ( _OLDNAME ) )
									_HMG_SYSDATA [31] [Z] := _NEWNAME
								ENDIF
							ENDIF

							IF _HMG_SYSDATA [1] [Z] == 'FRAME' .AND. VALTYPE ( _HMG_SYSDATA [31] [Z] ) == 'C'
								IF HMG_UPPER ( ALLTRIM ( _HMG_SYSDATA [31] [Z] ) ) == HMG_UPPER ( ALLTRIM ( _OLDNAME ) )
									_HMG_SYSDATA [31] [Z] := _NEWNAME
								ENDIF
							ENDIF

						NEXT Z

						__MVPUBLIC ( Result + 'MultiLine' ) 
						__MVPUT( Result + 'Multiline' ,  __MVGET ( PreviousValue + 'Multiline' ) )
						__MVXRELEASE( PreviousValue + 'Multiline' )

						__MVPUBLIC ( Result + 'PageCount' ) 
						__MVPUT( Result + 'PageCount' ,  __MVGET ( PreviousValue + 'PageCount' ) )
						__MVXRELEASE( PreviousValue + 'PageCount' )

						__MVPUBLIC ( Result + 'Captions' ) 
						__MVPUT( Result + 'Captions' ,  __MVGET ( PreviousValue + 'Captions' ) )
						__MVXRELEASE( PreviousValue + 'Captions' )

						__MVPUBLIC ( Result + 'PageImages' ) 
						__MVPUT( Result + 'PageImages' ,  __MVGET ( PreviousValue + 'PageImages' ) )
						__MVXRELEASE( PreviousValue + 'PageImages' )

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'OnChange' ) 
						__MVPUT( Result + 'OnChange' ,  __MVGET ( PreviousValue + 'OnChange' ) )
						__MVXRELEASE( PreviousValue + 'OnChange' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'Buttons' ) 
						__MVPUT( Result + 'Buttons' ,  __MVGET ( PreviousValue + 'Buttons' ) )
						__MVXRELEASE( PreviousValue + 'Buttons' )

						__MVPUBLIC ( Result + 'Flat' ) 
						__MVPUT( Result + 'Flat' ,  __MVGET ( PreviousValue + 'Flat' ) )
						__MVXRELEASE( PreviousValue + 'Flat' )

						__MVPUBLIC ( Result + 'Vertical' ) 
						__MVPUT( Result + 'Vertical' ,  __MVGET ( PreviousValue + 'Vertical' ) )
						__MVXRELEASE( PreviousValue + 'Vertical' )

						__MVPUBLIC ( Result + 'HotTrack' ) 
						__MVPUT( Result + 'HotTrack' ,  __MVGET ( PreviousValue + 'HotTrack' ) )
						__MVXRELEASE( PreviousValue + 'HotTrack' )

						__MVPUBLIC ( Result + 'TabStop' ) 
						__MVPUT( Result + 'TabStop' ,  __MVGET ( PreviousValue + 'TabStop' ) )
						__MVXRELEASE( PreviousValue + 'TabStop' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'PAGECOUNT'

					if VAL ( PreviousValue ) != VAL ( Result )

						__MVPUT( SelectedControlName + 'PageCount' , Result )
						
						if VAL ( Result ) > VAL ( PreviousValue )

							x := GetControlIndex ( SelectedControlName , DesignForm )
				
							For a := 1 To VAL ( Result ) - VAL ( PreviousValue )
					
								DoMethod ( DesignForm , SelectedControlName , 'AddPage' , VAL ( PreviousValue ) + a , 'Page ' + ALLTRIM(STR( VAL ( PreviousValue ) + a )))
								_HMG_SYSDATA [ 33 ] [x] [ VAL ( PreviousValue ) + a ] :=  'Page ' + ALLTRIM(STR( VAL ( PreviousValue ) + a ) )

							Next a

						        cTemp := '{ '
							For a := 1 To HMG_LEN ( _HMG_SYSDATA [ 33 ] [x] )			
								cTemp := cTemp + chr(34) + _HMG_SYSDATA [ 33 ] [x] [a] + chr(34) + ' , '
							Next a
					                cTemp := ALLTRIM (cTemp)
							cTemp := HB_ULEFT ( cTemp , HMG_LEN(cTemp) - 1 )
							cTemp := cTemp + '} '
							__MVPUT (_HMG_SYSDATA [   2 ] [x] + 'Captions' , cTemp )
							__MVPUT (_HMG_SYSDATA [   2 ] [x] + 'PageCount' , ALLTRIM(STR(HMG_LEN(_HMG_SYSDATA [ 7 ][x]))) )


***

							aTemp := StringToArray ( __MVGET( SelectedControlName + 'PageImages' ) )

						        cTemp := '{ '
							For a := 1 To HMG_LEN ( aTemp )			
								cTemp := cTemp + chr(34) + aTemp [a] + chr(34) + ' , '
							Next a

							For a := 1 To HMG_LEN ( _HMG_SYSDATA [ 33 ] [x] ) - HMG_LEN ( aTemp )
								cTemp := cTemp + chr(34) + '' + chr(34) + ' , '
							Next a

					                cTemp := ALLTRIM (cTemp)
							cTemp := HB_ULEFT ( cTemp , HMG_LEN(cTemp) - 1 )
							cTemp := cTemp + '} '
							__MVPUT (_HMG_SYSDATA [   2 ] [x] + 'PageImages' , cTemp )

***

	
						Elseif VAL ( Result ) < VAL ( PreviousValue )

							aTemp := {}
				
							x1 := GetControlIndex ( SelectedControlName , DesignForm )

							lSuccess := .T.

							For a := VAL ( PreviousValue )  To VAL ( Result ) + 1 Step -1

								if HMG_LEN ( _HMG_SYSDATA [  7 ] [x1] [a] ) > 0 

									MsgStop ( aMsgs [ 223 ] ,'HMG IDE')
									__MVPUT( SelectedControlName + 'PageCount' , PreviousValue )
									
									lSuccess := .F.
									exit
								else
									DoMethod ( DesignForm , SelectedControlName , 'DeletePage' , a )
								endif

							next a

							If lSuccess == .T.

							        cTemp := '{ '
								For y := 1 To HMG_LEN ( _HMG_SYSDATA [ 33 ] [x1] )			
									cTemp := cTemp + chr(34) + _HMG_SYSDATA [ 33 ] [x1] [y] + chr(34) + ' , '
								Next y
						                cTemp := ALLTRIM (cTemp)
								cTemp := HB_ULEFT ( cTemp , HMG_LEN(cTemp) - 1 )
								cTemp := cTemp + '} '
								__MVPUT (_HMG_SYSDATA [   2 ] [x1] + 'Captions' , cTemp )


								x := GetControlIndex ( SelectedControlName , DesignForm )

								aTemp := StringToArray ( __MVGET( SelectedControlName + 'PageImages' ) )

							        cTemp := '{ '
								For a := 1 To HMG_LEN ( _HMG_SYSDATA [ 33 ] [x] )			
									cTemp := cTemp + chr(34) + aTemp [a] + chr(34) + ' , '
								Next a

					        	        cTemp := ALLTRIM (cTemp)
								cTemp := HB_ULEFT ( cTemp , HMG_LEN(cTemp) - 1 )
								cTemp := cTemp + '} '
								__MVPUT (_HMG_SYSDATA [   2 ] [x] + 'PageImages' , cTemp )

							endif

						EndIf

					EndIf

					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'CAPTIONS'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					aTemp := StringToArray ( Result )

					if HMG_LEN (aTemp) != VAL ( __MVGET (SelectedControlName + 'PageCount' ) )
						MsgStop ('Captions Array Length Must Be Equal To PageCount Value. Aborted','HMG IDE')
						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)
						RETURN
					EndIf

					__MVPUT( SelectedControlName + 'Captions' , Result )

                                        					
					For k := 1 To HMG_LEN ( _HMG_SYSDATA [ 33 ] [x] )
						SetProperty ( DesignForm , SelectedControlName , 'Caption' , k , aTemp [k] )
					Next k

					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)


				ElseIf PropertyName == 'BUTTONS'

					if	ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Buttons'	) ) ) == '.T.'	;
						.and. ;
						IsAppThemed() ;
						.and. ;
						ALLTRIM ( HMG_UPPER ( Result ) ) == '.F.'
		
						__MVPUT( SelectedControlName + 'Vertical' , '.F.' )

					endif

					__MVPUT( SelectedControlName + 'Buttons' , Result )

					TabMultiline	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Multiline'	) ) ) == '.T.' , .T. , .F. )

					TabIndex	:= GetControlIndex ( SelectedControlName , DesignForm )
					TabRow		:= GetProperty ( DesignForm , SelectedControlName , 'Row' )
					TabCol		:= GetProperty ( DesignForm , SelectedControlName , 'Col' )
					TabWidth	:= GetProperty ( DesignForm , SelectedControlName , 'Width' )
					TabHeight	:= GetProperty ( DesignForm , SelectedControlName , 'Height' )
					TabCaptions	:= _HMG_SYSDATA [ 33 ]   [TabIndex]
					TabPage		:= GetProperty ( DesignForm , SelectedControlName , 'Value' )
					TabButtons	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Buttons'	) ) ) == '.T.' , .T. , .F. )
					TabFlat		:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Flat'	) ) ) == '.T.' , .T. , .F. )
					TabHotTrack	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'HotTrack'	) ) ) == '.T.' , .T. , .F. )
					TabVertical	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Vertical'	) ) ) == '.T.' , .T. , .F. )
					TabFontName	:= __MVGET ( SelectedControlName + 'FontName' ) 
					TabFontSize	:= VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )
					TabBold		:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontBold'	) ) ) == '.T.' , .T. , .F. )
					TabItalic	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontItalic'	) ) ) == '.T.' , .T. , .F. )
					TabUnderLine	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontUnderLine'	) ) ) == '.T.' , .T. , .F. )
					TabStrikeout	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontStrikeout'	) ) ) == '.T.' , .T. , .F. )
					releaseControl (_HMG_SYSDATA [   3 ] [tabindex] )
					_HMG_SYSDATA [   3 ] [TabIndex] := InitTabControl ( DesignFormhandle, 0, TabCol , TabRow , TabWidth , TabHeight , TabCaptions , TabPage, '', 0 , TabButtons , TabFlat , TabHottrack , TabVertical , .f. , TabMultiline )
					DeleteObject ( _HMG_SYSDATA [ 36 ] [tabindex] ) 
					_HMG_SYSDATA [ 36 ] [TabIndex] := _SetFont ( _HMG_SYSDATA [   3 ] [TabIndex] , TabFontName , TabFontSize , TabBold , TabItalic , TabUnderLine , TabStrikeout )


					for x := 1 to HMG_LEN ( _hmg_sysdata [1] )

						if	_hmg_sysdata [1] [x] == 'SLIDER' ;
							.or. ;
							_hmg_sysdata [1] [x] == 'FRAME' ;
							.or. ;
							_hmg_sysdata [1] [x] == 'CHECKBOX' ;
							.or. ;
							_hmg_sysdata [1] [x] == 'RADIOGROUP' 

							_hmg_sysdata [16] [x] := TabButtons 

						endif

						if	_hmg_sysdata [1] [x] == 'SLIDER' 

							_hmg_sysdata [36] [x] := SelectedControlName
							_hmg_sysdata [37] [x] := dESIGNfORM 

							SetFocus ( _hmg_sysdata [3] [x] )

						ENDIF

					next x

					_HMG_SYSDATA [ 31 ]   [TabIndex] := TabButtons

					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FLAT'
					__MVPUT( SelectedControlName + 'Flat' , Result )

					TabMultiline	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Multiline'	) ) ) == '.T.' , .T. , .F. )


					TabIndex	:= GetControlIndex ( SelectedControlName , DesignForm )
					TabRow		:= GetProperty ( DesignForm , SelectedControlName , 'Row' )
					TabCol		:= GetProperty ( DesignForm , SelectedControlName , 'Col' )
					TabWidth	:= GetProperty ( DesignForm , SelectedControlName , 'Width' )
					TabHeight	:= GetProperty ( DesignForm , SelectedControlName , 'Height' )
					TabCaptions	:= _HMG_SYSDATA [ 33 ]   [TabIndex]
					TabPage		:= GetProperty ( DesignForm , SelectedControlName , 'Value' )
					TabButtons	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Buttons'	) ) ) == '.T.' , .T. , .F. )
					TabFlat		:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Flat'	) ) ) == '.T.' , .T. , .F. )
					TabHotTrack	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'HotTrack'	) ) ) == '.T.' , .T. , .F. )
					TabVertical	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Vertical'	) ) ) == '.T.' , .T. , .F. )
					TabFontName	:= __MVGET ( SelectedControlName + 'FontName' ) 
					TabFontSize	:= VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )
					TabBold		:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontBold'	) ) ) == '.T.' , .T. , .F. )
					TabItalic	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontItalic'	) ) ) == '.T.' , .T. , .F. )
					TabUnderLine	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontUnderLine'	) ) ) == '.T.' , .T. , .F. )
					TabStrikeout	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontStrikeOut'	) ) ) == '.T.' , .T. , .F. )
					releaseControl (_HMG_SYSDATA [   3 ] [tabindex] )
					_HMG_SYSDATA [   3 ] [TabIndex] := InitTabControl ( DesignFormhandle, 0, TabCol , TabRow , TabWidth , TabHeight , TabCaptions , TabPage, '', 0 , TabButtons , TabFlat , TabHottrack , TabVertical , .f. , TabMultiline )
					DeleteObject ( _HMG_SYSDATA [ 36 ] [tabindex] ) 
					_HMG_SYSDATA [ 36 ] [TabIndex] := _SetFont ( _HMG_SYSDATA [   3 ] [TabIndex] , TabFontName , TabFontSize , TabBold , TabItalic , TabUnderLine , TabStrikeout )


					for x := 1 to HMG_LEN ( _hmg_sysdata [1] )

						if	_hmg_sysdata [1] [x] == 'SLIDER' ;
							.or. ;
							_hmg_sysdata [1] [x] == 'FRAME' ;
							.or. ;
							_hmg_sysdata [1] [x] == 'CHECKBOX' ;
							.or. ;
							_hmg_sysdata [1] [x] == 'RADIOGROUP' 

							_hmg_sysdata [16] [x] := TabButtons 

						endif

						if	_hmg_sysdata [1] [x] == 'SLIDER' 

							_hmg_sysdata [36] [x] := SelectedControlName
							_hmg_sysdata [37] [x] := dESIGNfORM 

							SetFocus ( _hmg_sysdata [3] [x] )

						ENDIF

					NEXT X

					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HOTTRACK'
					__MVPUT( SelectedControlName + 'HotTrack' , Result )

					TabMultiline	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Multiline'	) ) ) == '.T.' , .T. , .F. )


					TabIndex	:= GetControlIndex ( SelectedControlName , DesignForm )
					TabRow		:= GetProperty ( DesignForm , SelectedControlName , 'Row' )
					TabCol		:= GetProperty ( DesignForm , SelectedControlName , 'Col' )
					TabWidth	:= GetProperty ( DesignForm , SelectedControlName , 'Width' )
					TabHeight	:= GetProperty ( DesignForm , SelectedControlName , 'Height' )
					TabCaptions	:= _HMG_SYSDATA [ 33 ]   [TabIndex]
					TabPage		:= GetProperty ( DesignForm , SelectedControlName , 'Value' )
					TabButtons	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Buttons'	) ) ) == '.T.' , .T. , .F. )
					TabFlat		:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Flat'	) ) ) == '.T.' , .T. , .F. )
					TabHotTrack	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'HotTrack'	) ) ) == '.T.' , .T. , .F. )
					TabVertical	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Vertical'	) ) ) == '.T.' , .T. , .F. )
					TabFontName	:= __MVGET ( SelectedControlName + 'FontName' ) 
					TabFontSize	:= VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )
					TabBold		:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontBold'	) ) ) == '.T.' , .T. , .F. )
					TabItalic	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontItalic'	) ) ) == '.T.' , .T. , .F. )
					TabUnderLine	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontUnderLine'	) ) ) == '.T.' , .T. , .F. )
					TabStrikeout	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontStrikeOut'	) ) ) == '.T.' , .T. , .F. )
					releaseControl (_HMG_SYSDATA [   3 ] [tabindex] )
					_HMG_SYSDATA [   3 ] [TabIndex] := InitTabControl ( DesignFormhandle, 0, TabCol , TabRow , TabWidth , TabHeight , TabCaptions , TabPage, '', 0 , TabButtons , TabFlat , TabHottrack , TabVertical , .f. , TabMultiline )
					DeleteObject ( _HMG_SYSDATA [ 36 ] [tabindex] ) 
					_HMG_SYSDATA [ 36 ] [TabIndex] := _SetFont ( _HMG_SYSDATA [   3 ] [TabIndex] , TabFontName , TabFontSize , TabBold , TabItalic , TabUnderLine , TabStrikeout )

					for x := 1 to HMG_LEN ( _hmg_sysdata [1] )

						if	_hmg_sysdata [1] [x] == 'SLIDER' ;
							.or. ;
							_hmg_sysdata [1] [x] == 'FRAME' ;
							.or. ;
							_hmg_sysdata [1] [x] == 'CHECKBOX' ;
							.or. ;
							_hmg_sysdata [1] [x] == 'RADIOGROUP' 

							_hmg_sysdata [16] [x] := TabButtons 

						endif

						if	_hmg_sysdata [1] [x] == 'SLIDER' 

							_hmg_sysdata [36] [x] := SelectedControlName
							_hmg_sysdata [37] [x] := dESIGNfORM 

							SetFocus ( _hmg_sysdata [3] [x] )

						ENDIF

					NEXT X

					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VERTICAL'

					__MVPUT( SelectedControlName + 'Vertical' , Result )

					if	( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Buttons'	) ) ) == '.T.' ) ;
						.or.;
						( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Buttons'	) ) ) == '.F.' .and. !IsAppThemed() .and. !IsVista() )

					TabMultiline	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Multiline'	) ) ) == '.T.' , .T. , .F. )


					TabIndex	:= GetControlIndex ( SelectedControlName , DesignForm )
					TabRow		:= GetProperty ( DesignForm , SelectedControlName , 'Row' )
					TabCol		:= GetProperty ( DesignForm , SelectedControlName , 'Col' )
					TabWidth	:= GetProperty ( DesignForm , SelectedControlName , 'Width' )
					TabHeight	:= GetProperty ( DesignForm , SelectedControlName , 'Height' )
					TabCaptions	:= _HMG_SYSDATA [ 33 ]   [TabIndex]
					TabPage		:= GetProperty ( DesignForm , SelectedControlName , 'Value' )
					TabButtons	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Buttons'	) ) ) == '.T.' , .T. , .F. )
					TabFlat		:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Flat'	) ) ) == '.T.' , .T. , .F. )
					TabHotTrack	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'HotTrack'	) ) ) == '.T.' , .T. , .F. )
					TabVertical	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Vertical'	) ) ) == '.T.' , .T. , .F. )
					TabFontName	:= __MVGET ( SelectedControlName + 'FontName' ) 
					TabFontSize	:= VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )
					TabBold		:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontBold'	) ) ) == '.T.' , .T. , .F. )
					TabItalic	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontItalic'	) ) ) == '.T.' , .T. , .F. )
					TabUnderLine	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontUnderLine'	) ) ) == '.T.' , .T. , .F. )
					TabStrikeout	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontStrikeOut'	) ) ) == '.T.' , .T. , .F. )
					releaseControl (_HMG_SYSDATA [   3 ] [tabindex] )
					_HMG_SYSDATA [   3 ] [TabIndex] := InitTabControl ( DesignFormhandle, 0, TabCol , TabRow , TabWidth , TabHeight , TabCaptions , TabPage, '', 0 , TabButtons , TabFlat , TabHottrack , TabVertical , .f. , TabMultiline )
					DeleteObject ( _HMG_SYSDATA [ 36 ] [tabindex] ) 
					_HMG_SYSDATA [ 36 ] [TabIndex] := _SetFont ( _HMG_SYSDATA [   3 ] [TabIndex] , TabFontName , TabFontSize , TabBold , TabItalic , TabUnderLine , TabStrikeout )

					for x := 1 to HMG_LEN ( _hmg_sysdata [1] )

						if	_hmg_sysdata [1] [x] == 'SLIDER' ;
							.or. ;
							_hmg_sysdata [1] [x] == 'FRAME' ;
							.or. ;
							_hmg_sysdata [1] [x] == 'CHECKBOX' ;
							.or. ;
							_hmg_sysdata [1] [x] == 'RADIOGROUP' 

							_hmg_sysdata [16] [x] := TabButtons 

						endif

						if	_hmg_sysdata [1] [x] == 'SLIDER' 

							_hmg_sysdata [36] [x] := SelectedControlName
							_hmg_sysdata [37] [x] := dESIGNfORM 

							SetFocus ( _hmg_sysdata [3] [x] )

						ENDIF

					NEXT X

					endif

					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'PAGEIMAGES'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					aTemp := StringToArray ( Result )

					if HMG_LEN (aTemp) != VAL ( __MVGET (SelectedControlName + 'PageCount' ) )
						MsgStop ('Images Array Length Must Be Equal To PageCount Value. Aborted','HMG IDE')
						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)
						RETURN
					EndIf

					__MVPUT( SelectedControlName + 'PageImages' , Result )

					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TABSTOP'
					__MVPUT( SelectedControlName + 'TabStop' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'MULTILINE'
					__MVPUT( SelectedControlName + 'Multiline' , Result )

					TabMultiline	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Multiline'	) ) ) == '.T.' , .T. , .F. )


					TabIndex	:= GetControlIndex ( SelectedControlName , DesignForm )
					TabRow		:= GetProperty ( DesignForm , SelectedControlName , 'Row' )
					TabCol		:= GetProperty ( DesignForm , SelectedControlName , 'Col' )
					TabWidth	:= GetProperty ( DesignForm , SelectedControlName , 'Width' )
					TabHeight	:= GetProperty ( DesignForm , SelectedControlName , 'Height' )
					TabCaptions	:= _HMG_SYSDATA [ 33 ]   [TabIndex]
					TabPage		:= GetProperty ( DesignForm , SelectedControlName , 'Value' )
					TabButtons	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Buttons'	) ) ) == '.T.' , .T. , .F. )
					TabFlat		:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Flat'	) ) ) == '.T.' , .T. , .F. )
					TabHotTrack	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'HotTrack'	) ) ) == '.T.' , .T. , .F. )
					TabVertical	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'Vertical'	) ) ) == '.T.' , .T. , .F. )
					TabFontName	:= __MVGET ( SelectedControlName + 'FontName' ) 
					TabFontSize	:= VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )
					TabBold		:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontBold'	) ) ) == '.T.' , .T. , .F. )
					TabItalic	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontItalic'	) ) ) == '.T.' , .T. , .F. )
					TabUnderLine	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontUnderLine'	) ) ) == '.T.' , .T. , .F. )
					TabStrikeout	:= if ( ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlName + 'FontStrikeOut'	) ) ) == '.T.' , .T. , .F. )
					releaseControl (_HMG_SYSDATA [   3 ] [tabindex] )
					_HMG_SYSDATA [   3 ] [TabIndex] := InitTabControl ( DesignFormhandle, 0, TabCol , TabRow , TabWidth , TabHeight , TabCaptions , TabPage, '', 0 , TabButtons , TabFlat , TabHottrack , TabVertical , .f. , TabMultiline )
					DeleteObject ( _HMG_SYSDATA [ 36 ] [tabindex] ) 
					_HMG_SYSDATA [ 36 ] [TabIndex] := _SetFont ( _HMG_SYSDATA [   3 ] [TabIndex] , TabFontName , TabFontSize , TabBold , TabItalic , TabUnderLine , TabStrikeout )


					for x := 1 to HMG_LEN ( _hmg_sysdata [1] )

						if	_hmg_sysdata [1] [x] == 'SLIDER' ;
							.or. ;
							_hmg_sysdata [1] [x] == 'FRAME' ;
							.or. ;
							_hmg_sysdata [1] [x] == 'CHECKBOX' ;
							.or. ;
							_hmg_sysdata [1] [x] == 'RADIOGROUP' 

							_hmg_sysdata [16] [x] := TabButtons 

						endif

						if	_hmg_sysdata [1] [x] == 'SLIDER' 

							_hmg_sysdata [36] [x] := SelectedControlName
							_hmg_sysdata [37] [x] := dESIGNfORM 

							SetFocus ( _hmg_sysdata [3] [x] )

						ENDIF

					NEXT X

					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'ANIMATEBOX'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						__MVPUBLIC ( Result + 'File' ) 
						__MVPUT( Result + 'File' ,  __MVGET ( PreviousValue + 'File' ) )
						__MVXRELEASE( PreviousValue + 'File' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'Transparent' ) 
						__MVPUT( Result + 'Transparent' ,  __MVGET ( PreviousValue + 'Transparent' ) )
						__MVXRELEASE( PreviousValue + 'Transparent' )

						__MVPUBLIC ( Result + 'AutoPlay' ) 
						__MVPUT( Result + 'AutoPlay' ,  __MVGET ( PreviousValue + 'AutoPlay' ) )
						__MVXRELEASE( PreviousValue + 'AutoPlay' )

						__MVPUBLIC ( Result + 'Center' ) 
						__MVPUT( Result + 'Center' ,  __MVGET ( PreviousValue + 'Center' ) )
						__MVXRELEASE( PreviousValue + 'Center' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FILE'
					__MVPUT( SelectedControlName + 'File' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TRANSPARENT'
					__MVPUT( SelectedControlName + 'Transparent' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'AUTOPLAY'
					__MVPUT( SelectedControlName + 'AutoPlay' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'CENTER'
					__MVPUT( SelectedControlName + 'Center' , Result )
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'HYPERLINK'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'Address' ) 
						__MVPUT( Result + 'Address' ,  __MVGET ( PreviousValue + 'Address' ) )
						__MVXRELEASE( PreviousValue + 'Address' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'AutoSize' ) 
						__MVPUT( Result + 'AutoSize' ,  __MVGET ( PreviousValue + 'AutoSize' ) )
						__MVXRELEASE( PreviousValue + 'AutoSize' )

						__MVPUBLIC ( Result + 'BackColor' ) 
						__MVPUT( Result + 'BackColor' ,  __MVGET ( PreviousValue + 'BackColor' ) )
						__MVXRELEASE( PreviousValue + 'BackColor' )

						__MVPUBLIC ( Result + 'FontColor' ) 
						__MVPUT( Result + 'FontColor' ,  __MVGET ( PreviousValue + 'FontColor' ) )
						__MVXRELEASE( PreviousValue + 'FontColor' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' ,  __MVGET ( PreviousValue + 'Visible' ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'HandCursor' ) 
						__MVPUT( Result + 'HandCursor' ,  __MVGET ( PreviousValue + 'HandCursor' ) )
						__MVXRELEASE( PreviousValue + 'HandCursor' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ADDRESS'
					__MVPUT( SelectedControlName + 'Address' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'AUTOSIZE'
					__MVPUT( SelectedControlName + 'AutoSize' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'BACKCOLOR'
					__MVPUT( SelectedControlName + 'BackColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 14 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTCOLOR'
					__MVPUT( SelectedControlName + 'FontColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'FontColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 15 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HANDCURSOR'
					__MVPUT( SelectedControlName + 'HandCursor' , Result )
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'MONTHCALENDAR'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'OnChange' ) 
						__MVPUT( Result + 'OnChange' ,  __MVGET ( PreviousValue + 'OnChange' ) )
						__MVXRELEASE( PreviousValue + 'OnChange' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'Today' ) 
						__MVPUT( Result + 'Today' ,  __MVGET ( PreviousValue + 'Today' ) )
						__MVXRELEASE( PreviousValue + 'Today' )

						__MVPUBLIC ( Result + 'TodayCircle' ) 
						__MVPUT( Result + 'TodayCircle' ,  __MVGET ( PreviousValue + 'TodayCircle' ) )
						__MVXRELEASE( PreviousValue + 'TodayCircle' )

						__MVPUBLIC ( Result + 'WeekNumbers' ) 
						__MVPUT( Result + 'WeekNumbers' ,  __MVGET ( PreviousValue + 'WeekNumbers' ) )
						__MVXRELEASE( PreviousValue + 'WeekNumbers' )

						__MVPUBLIC ( Result + 'TabStop' ) 
						__MVPUT( Result + 'TabStop' ,  __MVGET ( PreviousValue + 'TabStop' ) )
						__MVXRELEASE( PreviousValue + 'TabStop' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' ,  __MVGET ( PreviousValue + 'Visible' ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE MONTHCALENDAR &SelectedControlName
						ROW RowTemp
						COL ColTemp
						PARENT &DesignForm
						ON CHANGE SelectControl (This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'Today' )    )) == '.T.'
							NOTODAY .F.
						else
							NOTODAY .T.
						endif
						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'TodayCircle' )    )) == '.T.'
							NOTODAYCIRCLE .F.
						else
							NOTODAYCIRCLE .T.
						endif
						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'WeekNumbers' )    )) == '.T.'
							WEEKNUMBERS .T.
						else
							WEEKNUMBERS .F.
						endif

					END MONTHCALENDAR

					if ! empty ( TabName )

						TabPage := GetProperty ( DesignForm , TabName , 'Value' )

						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )

						DrawGrid()

						_HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] := TabName
	
					EndIf

					RedrawWindow (DesignForm)
					DrawGrid()
					SelectControl (SelectedControlName)
					DrawGrid()

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE MONTHCALENDAR &SelectedControlName
						ROW RowTemp
						COL ColTemp
						PARENT &DesignForm
						ON CHANGE SelectControl (This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'Today' )    )) == '.T.'
							NOTODAY .F.
						else
							NOTODAY .T.
						endif
						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'TodayCircle' )    )) == '.T.'
							NOTODAYCIRCLE .F.
						else
							NOTODAYCIRCLE .T.
						endif
						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'WeekNumbers' )    )) == '.T.'
							WEEKNUMBERS .T.
						else
							WEEKNUMBERS .F.
						endif

					END MONTHCALENDAR

					if ! empty ( TabName )

						TabPage := GetProperty ( DesignForm , TabName , 'Value' )

						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )

						DrawGrid()

						_HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] := TabName
	
					EndIf

					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TODAY'
					__MVPUT( SelectedControlName + 'Today' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE MONTHCALENDAR &SelectedControlName
						ROW RowTemp
						COL ColTemp
						PARENT &DesignForm
						ON CHANGE SelectControl (This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'Today' )    )) == '.T.'
							NOTODAY .F.
						else
							NOTODAY .T.
						endif
						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'TodayCircle' )    )) == '.T.'
							NOTODAYCIRCLE .F.
						else
							NOTODAYCIRCLE .T.
						endif
						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'WeekNumbers' )    )) == '.T.'
							WEEKNUMBERS .T.
						else
							WEEKNUMBERS .F.
						endif

					END MONTHCALENDAR

					if ! empty ( TabName )

						TabPage := GetProperty ( DesignForm , TabName , 'Value' )

						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )

						DrawGrid()

						_HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] := TabName
	
					EndIf

					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TODAYCIRCLE'

					__MVPUT( SelectedControlName + 'TodayCircle' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE MONTHCALENDAR &SelectedControlName
						ROW RowTemp
						COL ColTemp
						PARENT &DesignForm
						ON CHANGE SelectControl (This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'Today' )    )) == '.T.'
							NOTODAY .F.
						else
							NOTODAY .T.
						endif
						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'TodayCircle' )    )) == '.T.'
							NOTODAYCIRCLE .F.
						else
							NOTODAYCIRCLE .T.
						endif
						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'WeekNumbers' )    )) == '.T.'
							WEEKNUMBERS .T.
						else
							WEEKNUMBERS .F.
						endif

					END MONTHCALENDAR


					if ! empty ( TabName )

						TabPage := GetProperty ( DesignForm , TabName , 'Value' )

						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )

						DrawGrid()

						_HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] := TabName
	
					EndIf

					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WEEKNUMBERS'

					__MVPUT( SelectedControlName + 'WeekNumbers' , Result )

					RowTemp := GetProperty ( DesignForm , SelectedControlName , 'Row' )
					ColTemp := GetProperty ( DesignForm , SelectedControlName , 'Col' )

					TabName := _HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] 

					DoMethod ( DesignForm , SelectedControlName , 'Release' )

					DEFINE MONTHCALENDAR &SelectedControlName
						ROW RowTemp
						COL ColTemp
						PARENT &DesignForm
						ON CHANGE SelectControl (This.Name)
						FONTNAME __MVGET ( SelectedControlName + 'FontName' )
						FONTSIZE VAL ( __MVGET ( SelectedControlName + 'FontSize' ) )

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontBold' )  )) == '.T.'
							FONTBOLD .T.
						else
							FONTBOLD .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontItalic' )   )) == '.T.'
							FONTITALIC .T.
						else
							FONTITALIC .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontUnderLine' )    )) == '.T.'
							FONTUNDERLINE .T.
						else
							FONTUNDERLINE .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'FontStrikeOut' )    )) == '.T.'
							FONTSTRIKEOUT .T.
						else
							FONTSTRIKEOUT .F.
						endif

						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'Today' )    )) == '.T.'
							NOTODAY .F.
						else
							NOTODAY .T.
						endif
						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'TodayCircle' )    )) == '.T.'
							NOTODAYCIRCLE .F.
						else
							NOTODAYCIRCLE .T.
						endif
						if ALLTRIM(HMG_UPPER(  __MVGET ( SelectedControlName + 'WeekNumbers' )    )) == '.T.'
							WEEKNUMBERS .T.
						else
							WEEKNUMBERS .F.
						endif

					END MONTHCALENDAR

					if ! empty ( TabName )

						TabPage := GetProperty ( DesignForm , TabName , 'Value' )

						DoMethod ( DesignForm , TabName , 'AddControl' , SelectedControlName , TabPage , RowTemp , ColTemp )

						DrawGrid()

						_HMG_SYSDATA [ 31 ] [GetControlIndex ( SelectedControlName , DesignForm )] := TabName
	
					EndIf

					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TABSTOP'
					__MVPUT( SelectedControlName + 'TabStop' , Result )
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'RICHEDITBOX'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						SetProperty ( DesignForm , SelectedControlName , 'Value' , Result )

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'OnChange' ) 
						__MVPUT( Result + 'OnChange' ,  __MVGET ( PreviousValue + 'OnChange' ) )
						__MVXRELEASE( PreviousValue + 'OnChange' )

						__MVPUBLIC ( Result + 'OnGotFocus' ) 
						__MVPUT( Result + 'OnGotFocus' ,  __MVGET ( PreviousValue + 'OnGotFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnGotFocus' )

						__MVPUBLIC ( Result + 'OnLostFocus' ) 
						__MVPUT( Result + 'OnLostFocus' ,  __MVGET ( PreviousValue + 'OnLostFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnLostFocus' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'TabStop' ) 
						__MVPUT( Result + 'TabStop' ,  __MVGET ( PreviousValue + 'TabStop' ) )
						__MVXRELEASE( PreviousValue + 'TabStop' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' ,  __MVGET ( PreviousValue + 'Visible' ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'BackColor' ) 
						__MVPUT( Result + 'BackColor' ,  __MVGET ( PreviousValue + 'BackColor' ) )
						__MVXRELEASE( PreviousValue + 'BackColor' )

						__MVPUBLIC ( Result + 'MaxLength' ) 
						__MVPUT( Result + 'MaxLength' ,  __MVGET ( PreviousValue + 'MaxLength' ) )
						__MVXRELEASE( PreviousValue + 'MaxLength' )

						__MVPUBLIC ( Result + 'Field' ) 
						__MVPUT( Result + 'Field' ,  __MVGET ( PreviousValue + 'Field' ) )
						__MVXRELEASE( PreviousValue + 'Field' )

						__MVPUBLIC ( Result + 'ReadOnly' ) 
						__MVPUT( Result + 'ReadOnly' ,  __MVGET ( PreviousValue + 'ReadOnly' ) )
						__MVXRELEASE( PreviousValue + 'ReadOnly' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TABSTOP'
					__MVPUT( SelectedControlName + 'TabStop' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'BACKCOLOR'
					__MVPUT( SelectedControlName + 'BackColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &Result )
					elseif ALLTRIM(HMG_UPPER(result)) == 'NIL'
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , { GetRed(GetControlSysColor()) , GetGreen(GetControlSysColor()) , GetBlue(GetControlSysColor()) } )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'MAXLENGTH'
					__MVPUT( SelectedControlName + 'MaxLength' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FIELD'
					__MVPUT( SelectedControlName + 'Field' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'READONLY'
					__MVPUT( SelectedControlName + 'ReadOnly' , Result )
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'PROGRESSBAR'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						SetProperty ( DesignForm , SelectedControlName , 'Value' , Result )

						__MVPUBLIC ( Result + 'RangeMin' ) 
						__MVPUT( Result + 'RangeMin' ,  __MVGET ( PreviousValue + 'RangeMin' ) )
						__MVXRELEASE( PreviousValue + 'RangeMin' )

						__MVPUBLIC ( Result + 'RangeMax' ) 
						__MVPUT( Result + 'RangeMax' ,  __MVGET ( PreviousValue + 'RangeMax' ) )
						__MVXRELEASE( PreviousValue + 'RangeMax' )

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'BackColor' ) 
						__MVPUT( Result + 'BackColor' ,  __MVGET ( PreviousValue + 'BackColor' ) )
						__MVXRELEASE( PreviousValue + 'BackColor' )

						__MVPUBLIC ( Result + 'ForeColor' ) 
						__MVPUT( Result + 'ForeColor' ,  __MVGET ( PreviousValue + 'ForeColor' ) )
						__MVXRELEASE( PreviousValue + 'ForeColor' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' ,  __MVGET ( PreviousValue + 'Visible' ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'Smooth' ) 
						__MVPUT( Result + 'Smooth' ,  __MVGET ( PreviousValue + 'Smooth' ) )
						__MVXRELEASE( PreviousValue + 'Smooth' )

						__MVPUBLIC ( Result + 'Orientation' ) 
						__MVPUT( Result + 'Orientation' ,  __MVGET ( PreviousValue + 'Orientation' ) )
						__MVXRELEASE( PreviousValue + 'Orientation' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'RANGEMAX'
					__MVPUT( SelectedControlName + 'RangeMax' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'RANGEMIN'
					__MVPUT( SelectedControlName + 'RangeMin' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'BACKCOLOR'
					__MVPUT( SelectedControlName + 'BackColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'BackColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 14 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FORECOLOR'
					__MVPUT( SelectedControlName + 'ForeColor' , Result )
					if HB_ULEFT(ALLTRIM(result),1) == '{' .and. HB_URIGHT(ALLTRIM(result),1) == '}'
				        	SetProperty ( DesignForm , SelectedControlName , 'ForeColor' , &Result )
					elseif HMG_UPPER(ALLTRIM(result)) == 'NIL' .or. Empty(result)
						z := GetControlIndex ( SelectedControlName , DesignForm )
						_HMG_SYSDATA [ 15 ] [z] := Nil
						redrawwindow ( _HMG_SYSDATA [   3 ] [z] )
					else
						MsgStop('Invalid Color Array','HMG IDE')
					endif
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'SMOOTH'
					__MVPUT( SelectedControlName + 'Smooth' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ORIENTATION'

					If 	( HMG_UPPER ( ALLTRIM ( __MVGET( SelectedControlName + 'Orientation' ) ) ) == 'VERTICAL' ;
						.and. ;
						HMG_UPPER ( ALLTRIM ( Result ) ) == 'HORIZONTAL' ) 

						HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
						WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )

						SetProperty ( DesignForm , SelectedControlName , 'Width' , WidthTemp )
						SetProperty ( DesignForm , SelectedControlName , 'Height' , HeightTemp )

					ElseIf 	( HMG_UPPER ( ALLTRIM ( __MVGET( SelectedControlName + 'Orientation' ) ) ) == 'HORIZONTAL' ;
						.and. ;
						HMG_UPPER ( ALLTRIM ( Result ) ) == 'VERTICAL' ) 

						HeightTemp := GetProperty ( DesignForm , SelectedControlName , 'Width' )
						WidthTemp := GetProperty ( DesignForm , SelectedControlName , 'Height' )

						SetProperty ( DesignForm , SelectedControlName , 'Width' , WidthTemp )
						SetProperty ( DesignForm , SelectedControlName , 'Height' , HeightTemp )

					EndIf

					__MVPUT( SelectedControlName + 'Orientation' , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'PLAYER'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						SetProperty ( DesignForm , SelectedControlName , 'Value' , Result )

						__MVPUBLIC ( Result + 'File' ) 
						__MVPUT( Result + 'File' ,  __MVGET ( PreviousValue + 'File' ) )
						__MVXRELEASE( PreviousValue + 'File' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						__MVPUBLIC ( Result + 'AutoSizeWindow' ) 
						__MVPUT( Result + 'AutoSizeWindow' ,  __MVGET ( PreviousValue + 'AutoSizeWindow' ) )
						__MVXRELEASE( PreviousValue + 'AutoSizeWindow' )

						__MVPUBLIC ( Result + 'AutoSizeMovie' ) 
						__MVPUT( Result + 'AutoSizeMovie' ,  __MVGET ( PreviousValue + 'AutoSizeMovie' ) )
						__MVXRELEASE( PreviousValue + 'AutoSizeMovie' )

						__MVPUBLIC ( Result + 'ErrorDlg' ) 
						__MVPUT( Result + 'ErrorDlg' ,  __MVGET ( PreviousValue + 'ErrorDlg' ) )
						__MVXRELEASE( PreviousValue + 'ErrorDlg' )

						__MVPUBLIC ( Result + 'Menu' ) 
						__MVPUT( Result + 'Menu' ,  __MVGET ( PreviousValue + 'Menu' ) )
						__MVXRELEASE( PreviousValue + 'Menu' )

						__MVPUBLIC ( Result + 'Open' ) 
						__MVPUT( Result + 'Open' ,  __MVGET ( PreviousValue + 'Open' ) )
						__MVXRELEASE( PreviousValue + 'Open' )

						__MVPUBLIC ( Result + 'PlayBar' ) 
						__MVPUT( Result + 'PlayBar' ,  __MVGET ( PreviousValue + 'PlayBar' ) )
						__MVXRELEASE( PreviousValue + 'PlayBar' )

						__MVPUBLIC ( Result + 'ShowAll' ) 
						__MVPUT( Result + 'ShowAll' ,  __MVGET ( PreviousValue + 'ShowAll' ) )
						__MVXRELEASE( PreviousValue + 'ShowAll' )

						__MVPUBLIC ( Result + 'ShowMode' ) 
						__MVPUT( Result + 'ShowMode' ,  __MVGET ( PreviousValue + 'ShowMode' ) )
						__MVXRELEASE( PreviousValue + 'ShowMode' )

						__MVPUBLIC ( Result + 'ShowName' ) 
						__MVPUT( Result + 'ShowName' ,  __MVGET ( PreviousValue + 'ShowName' ) )
						__MVXRELEASE( PreviousValue + 'ShowName' )

						__MVPUBLIC ( Result + 'ShowPosition' ) 
						__MVPUT( Result + 'ShowPosition' ,  __MVGET ( PreviousValue + 'ShowPosition' ) )
						__MVXRELEASE( PreviousValue + 'ShowPosition' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FILE'
					__MVPUT( SelectedControlName + 'File' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'AUTOSIZEWINDOW'
					__MVPUT( SelectedControlName + 'AUTOSIZEWINDOW' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'AUTOSIZEMOVIE'
					__MVPUT( SelectedControlName + 'AUTOSIZEMOVIE' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'ERRORDLG'
					__MVPUT( SelectedControlName + 'ERRORDLG' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'MENU'
					__MVPUT( SelectedControlName + 'MENU' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'OPEN'
					__MVPUT( SelectedControlName + 'OPEN' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'PLAYBAR'
					__MVPUT( SelectedControlName + 'PLAYBAR' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'SHOWALL'
					__MVPUT( SelectedControlName + 'SHOWALL' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'SHOWMODE'
					__MVPUT( SelectedControlName + 'SHOWMODE' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'SHOWNAME'
					__MVPUT( SelectedControlName + 'SHOWNAME' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'SHOWPOSITION'
					__MVPUT( SelectedControlName + 'SHOWPOSITION' , Result )
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'ACTIVEX'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						__MVPUBLIC ( Result + 'ProgId' ) 
						__MVPUT( Result + 'ProgId' ,  __MVGET ( PreviousValue + 'ProgId' ) )
						__MVXRELEASE( PreviousValue + 'ProgId' )


						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						SetProperty ( DesignForm , SelectedControlName , 'Value' , Result )

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'PROGID'
					__MVPUT( SelectedControlName + 'PROGID' , Result )
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'WINDOW'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						SetProperty ( DesignForm , SelectedControlName , 'Value' , Result )

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'IPADDRESS'
			*******************************************************

				If PropertyName == 'ROW'
	
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)


				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						SetProperty ( DesignForm , SelectedControlName , 'Value' , Result )

						__MVPUBLIC ( Result + 'Value' ) 
						__MVPUT( Result + 'Value' ,  __MVGET ( PreviousValue + 'Value' ) )
						__MVXRELEASE( PreviousValue + 'Value' )

						__MVPUBLIC ( Result + 'FontName' ) 
						__MVPUT( Result + 'FontName' ,  __MVGET ( PreviousValue + 'FontName' ) )
						__MVXRELEASE( PreviousValue + 'FontName' )

						__MVPUBLIC ( Result + 'FontSize' ) 
						__MVPUT( Result + 'FontSize' ,  __MVGET ( PreviousValue + 'FontSize' ) )
						__MVXRELEASE( PreviousValue + 'FontSize' )

						__MVPUBLIC ( Result + 'ToolTip' ) 
						__MVPUT( Result + 'ToolTip' ,  __MVGET ( PreviousValue + 'ToolTip' ) )
						__MVXRELEASE( PreviousValue + 'ToolTip' )

						__MVPUBLIC ( Result + 'OnChange' ) 
						__MVPUT( Result + 'OnChange' ,  __MVGET ( PreviousValue + 'OnChange' ) )
						__MVXRELEASE( PreviousValue + 'OnChange' )

						__MVPUBLIC ( Result + 'OnGotFocus' ) 
						__MVPUT( Result + 'OnGotFocus' ,  __MVGET ( PreviousValue + 'OnGotFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnGotFocus' )

						__MVPUBLIC ( Result + 'OnLostFocus' ) 
						__MVPUT( Result + 'OnLostFocus' ,  __MVGET ( PreviousValue + 'OnLostFocus' ) )
						__MVXRELEASE( PreviousValue + 'OnLostFocus' )

						__MVPUBLIC ( Result + 'FontBold' ) 
						__MVPUT( Result + 'FontBold' ,  __MVGET ( PreviousValue + 'FontBold' ) )
						__MVXRELEASE( PreviousValue + 'FontBold' )

						__MVPUBLIC ( Result + 'FontItalic' ) 
						__MVPUT( Result + 'FontItalic' ,  __MVGET ( PreviousValue + 'FontItalic' ) )
						__MVXRELEASE( PreviousValue + 'FontItalic' )

						__MVPUBLIC ( Result + 'FontStrikeOut' ) 
						__MVPUT( Result + 'FontStrikeOut' ,  __MVGET ( PreviousValue + 'FontStrikeOut' ) )
						__MVXRELEASE( PreviousValue + 'FontStrikeOut' )

						__MVPUBLIC ( Result + 'FontUnderLine' ) 
						__MVPUT( Result + 'FontUnderLine' ,  __MVGET ( PreviousValue + 'FontUnderLine' ) )
						__MVXRELEASE( PreviousValue + 'FontUnderLine' )

						__MVPUBLIC ( Result + 'TabStop' ) 
						__MVPUT( Result + 'TabStop' ,  __MVGET ( PreviousValue + 'TabStop' ) )
						__MVXRELEASE( PreviousValue + 'TabStop' )

						__MVPUBLIC ( Result + 'Visible' ) 
						__MVPUT( Result + 'Visible' ,  __MVGET ( PreviousValue + 'Visible' ) )
						__MVXRELEASE( PreviousValue + 'Visible' )

						__MVPUBLIC ( Result + 'HelpId' ) 
						__MVPUT( Result + 'HelpId' ,  __MVGET ( PreviousValue + 'HelpId' ) )
						__MVXRELEASE( PreviousValue + 'HelpId' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				ElseIf PropertyName == 'COL'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'WIDTH'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HEIGHT'
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VALUE'
					__MVPUT( SelectedControlName + 'Value' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTNAME'
					__MVPUT( SelectedControlName + 'FontName' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , Result )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSIZE'
					__MVPUT( SelectedControlName + 'FontSize' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , VAL ( Result ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TOOLTIP'
					__MVPUT( SelectedControlName + 'ToolTip' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTBOLD'
					__MVPUT( SelectedControlName + 'FontBold' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTITALIC'
					__MVPUT( SelectedControlName + 'FontItalic' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTUNDERLINE'
					__MVPUT( SelectedControlName + 'FontUnderLine' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'FONTSTRIKEOUT'
					__MVPUT( SelectedControlName + 'FontStrikeout' , Result )
					SetProperty ( DesignForm , SelectedControlName , PropertyName , if ( HMG_UPPER(ALLTRIM(Result)) == '.T.' , .T. , .F. ) )
					RedrawWindow (DesignForm)
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'VISIBLE'
					__MVPUT( SelectedControlName + 'Visible' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'TABSTOP'
					__MVPUT( SelectedControlName + 'TabStop' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'HELPID'
					__MVPUT( SelectedControlName + 'HelpId' , Result )
					SelectControl (SelectedControlName)

				EndIf

			*******************************************************
			ElseIf	SelectedControlType == 'TIMER'
			*******************************************************

				If PropertyName == 'INTERVAL'
					__MVPUT( SelectedControlName + 'Interval' , Result )
					SelectControl (SelectedControlName)

				ElseIf PropertyName == 'NAME'

					x := GetControlIndex ( SelectedControlName , DesignForm )
					if x > 0

						If ALLTRIM(HMG_UPPER(PreviousValue)) == ALLTRIM(HMG_UPPER(Result))
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						If !IsControNameValid ( Result )
							MsgStop('Control Name Duplicated or Invalid','HMG IDE')
							RedrawWindow (DesignForm)
							SelectControl (SelectedControlName)
							RETURN
						EndIf

						__MVPUBLIC ( Result + 'Interval' ) 
						__MVPUT( Result + 'Interval' ,  __MVGET ( PreviousValue + 'Interval' ) )
						__MVXRELEASE( PreviousValue + 'Interval' )

						__MVPUBLIC ( Result + 'Action' ) 
						__MVPUT( Result + 'Action' ,  __MVGET ( PreviousValue + 'Action' ) )
						__MVXRELEASE( PreviousValue + 'Action' )

						_HMG_SYSDATA [   2 ] [x] := Result

						__MVPUBLIC ( '_' + DesignForm + '_' + Result ) 
						__MVPUT( '_' + DesignForm + '_' + Result , x )

						__MVPUT( '_' + DesignForm + '_' + SelectedControlName , 0 )

						SelectedControlName := Result

						RedrawWindow (DesignForm)
						SelectControl (SelectedControlName)

					EndIf

				EndIf

			EndIf

		Else

			*-.*.-*.-*-.*-.*-.*-.*-.*-.*-.*-.*-.*-.*-.*-.*-.*-.*-.

			Properties.Grid_1.Item (i) := { aRow [1] , Result }

			if ALLTRIM( HMG_UPPER (aRow [1]) ) == 'TITLE'
				SetProperty ( DesignForm , aRow [1] , Result )


			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'VIRTUAL SIZED'

				If ALLTRIM( (HMG_UPPER ( Result) ) ) == '.T.'
					SetPropertyVirtualOn()
				elseIf ALLTRIM( (HMG_UPPER ( Result) ) ) == '.F.'
					SetPropertyVirtualOff()
				endif

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'VIRTUAL WIDTH'

				if VAL(Result) <= GetProperty( DesignForm , 'Width' )
					Properties.Grid_1.Item (i) := { aRow [1] , PreviousValue }
					MsgStop( 'Invalid Value' , 'ERROR' )
					RETURN
				else
					__MVPUT ( DesignForm + 'VirtualWidth' , Result )
					SetScrollRange ( DesignFormhandle , SB_HORZ , 0 , VAL(Result) - GetProperty( DesignForm , 'Width' ) , 1 )
				endif

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'VIRTUAL HEIGHT'

				if VAL(Result) <= GetProperty( DesignForm , 'Height' )
					Properties.Grid_1.Item (i) := { aRow [1] , PreviousValue }
					MsgStop( 'Invalid Value' , 'ERROR' )
					RETURN
				else
					__MVPUT ( DesignForm + 'VirtualHeight' , Result )
					SetScrollRange ( DesignFormhandle , SB_VERT , 0 , VAL(Result) - GetProperty( DesignForm , 'Height' ) , 1 )
				endif

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'WINDOWTYPE'
				__MVPUT ( DesignForm + 'WindowType' , Result )
				UpdateDesignFormProperties()

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'HELPBUTTON'
				__MVPUT ( DesignForm + 'HelpButton' , Result )

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'BACKCOLOR'
				__MVPUT ( DesignForm + 'BackColor' , Result )

				If ALLTRIM(HMG_UPPER(Result)) <> 'NIL'

					SetWindowBackColor ( DesignFormHandle , &Result )

				Else

					nTemp := GetWindowSysColor()
					aTemp := { GetRed(nTemp) , GetGreen(nTemp) , GetBlue(nTemp) }

					SetWindowBackColor ( DesignFormHandle , aTemp )

				EndIf

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'NOTIFYICON'
				__MVPUT ( DesignForm + 'NotifyIcon' , Result )

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'NOTIFYTOOLTIP'
				__MVPUT ( DesignForm + 'NotifyToolTip' , Result )

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'CURSOR'
				__MVPUT ( DesignForm + 'Cursor' , Result )

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'ICON'
				__MVPUT ( DesignForm + 'Icon' , Result )

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'VISIBLE'
				__MVPUT ( DesignForm + 'Visible' , Result )

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'TOPMOST'
				__MVPUT ( DesignForm + 'Topmost' , Result )

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'AUTORELEASE'
				__MVPUT ( DesignForm + 'AutoRelease' , Result )

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'MAXBUTTON'
				__MVPUT ( DesignForm + 'MaxButton' , Result )

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'MINBUTTON'
				__MVPUT ( DesignForm + 'MinButton' , Result )

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'SIZABLE'
				__MVPUT ( DesignForm + 'Sizable' , Result )

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'SYSMENU'
				__MVPUT ( DesignForm + 'SysMenu' , Result )

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'TITLEBAR'
				__MVPUT ( DesignForm + 'TitleBar' , Result )

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'BREAK'
				__MVPUT ( DesignForm + 'Break' , Result )

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'FOCUSED'
				__MVPUT ( DesignForm + 'Focused' , Result )

			Elseif ALLTRIM( HMG_UPPER (aRow [1]) ) == 'GRIPPERTEXT'
				__MVPUT ( DesignForm + 'GripperText' , Result )

			Else

				SetProperty ( DesignForm , aRow [1] , VAL ( Result ) )

			EndIf
			
                        RedrawWindow (DesignForm)
			SelectControl (SelectedControlName)

		EndIf

		Properties.Grid_1.Value := i
		Properties.Grid_1.SetFocus

	Else

		if ! Empty ( SelectedControlName )
			SelectControl (SelectedControlName)
		EndIf

		Properties.Grid_1.Value := i
		Properties.Grid_1.SetFocus

	EndIf

	DoMethod ( DesignForm , 'SetFocus' )

RETURN
