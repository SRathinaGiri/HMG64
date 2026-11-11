*------------------------------------------------------------------------------*
FUNCTION Save ( lView )
*------------------------------------------------------------------------------*
LOCAL aTemp
Local i
Local Code := ''
Local PageMap := {}
Local x
Local j
Local k
Local idx
Local RetVal := Nil
Local WindowType 
Local a
Local ImageFlag
Local b

	if ! IsWindowDefined(&DesignForm)
		MsgStop ( aMsgs [ 086 ] ,'HMG IDE')
		RETURN NIL
	EndIf

	if Empty ( OpenFormName )
		RETURN NIL
	EndIf

	WindowType := ALLTRIM ( HMG_UPPER ( __MVGET ( DesignForm + 'WindowType' ) ) )

	Code := Code + _GCN  + CRLF + CRLF

	If	WindowType == 'STANDARD' ;
		.Or. ;
		WindowType == 'MAIN' ;
		.Or. ;
		WindowType == 'CHILD' ;
		.Or. ;
		WindowType == 'PANEL' 


		Code := Code + 'DEFINE WINDOW TEMPLATE AT ' ;
		+ ALLTRIM(STR( GetProperty ( DesignForm , 'Row' ) )) ;
		+ ' , ' ;
		+  ALLTRIM(STR(GetProperty ( DesignForm , 'Col' ))) ;
		+ ' WIDTH ' ;
		+ ALLTRIM(STR(GetProperty ( DesignForm , 'Width' ))) ;
		+ ' HEIGHT ' ;
		+ ALLTRIM(STR(GetProperty ( DesignForm , 'Height' ))) ;
		+ ' VIRTUAL WIDTH ' ;
		+ ALLTRIM( __MVGET ( DesignForm + 'VirtualWidth' )) ;
		+ ' VIRTUAL HEIGHT ' ;
		+ ALLTRIM( __MVGET ( DesignForm + 'VirtualHeight' )) ;
		+ ' TITLE ' ;
		+ chr(34) + GetProperty ( DesignForm , 'Title' ) + chr(34) 

		if Empty (__MVGET ( DesignForm + 'Icon' ))
			Code := Code + ' ICON NIL'
		Else
			Code := Code + ' ICON ' + chr(34) + __MVGET ( DesignForm + 'Icon' ) + chr(34)
		EndIf

		Code := Code + ' ' + if ( HMG_UPPER ( __MVGET ( DesignForm+'WindowType' ) ) == 'STANDARD' , '' , HMG_UPPER ( __MVGET ( DesignForm+'WindowType' ) ) ) 

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'Visible' ) ) ) == '.F.' 
			Code := Code + ' NOSHOW'
		EndIf

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'Topmost' ) ) ) == '.T.' 
			Code := Code + ' TOPMOST'
		EndIf

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'AutoRelease' ) ) ) == '.F.' 
			Code := Code + ' NOAUTORELEASE'
		EndIf

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'MaxButton' ) ) ) == '.F.' 
			Code := Code + ' NOMAXIMIZE'
		EndIf

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'MinButton' ) ) ) == '.F.' 
			Code := Code + ' NOMINIMIZE'
		EndIf

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'Sizable' ) ) ) == '.F.' 
			Code := Code + ' NOSIZE'
		EndIf

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'SysMenu' ) ) ) == '.F.' 
			Code := Code + ' NOSYSMENU'
		EndIf

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'TitleBar' ) ) ) == '.F.' 
			Code := Code + ' NOCAPTION'
		EndIf

		if Empty (__MVGET ( DesignForm + 'Cursor' ))
			Code := Code + ' CURSOR NIL'
		Else
			Code := Code + ' CURSOR ' + chr(34) + __MVGET ( DesignForm + 'Cursor' ) + chr(34)
		EndIf

		Code := Code + ' ON INIT ' + __MVGET ( DesignForm + 'OnInit' )
		Code := Code + ' ON RELEASE ' + __MVGET ( DesignForm + 'OnRelease' )
		Code := Code + ' ON INTERACTIVECLOSE ' + __MVGET ( DesignForm + 'OnInteractiveClose' )
		Code := Code + ' ON MOUSECLICK ' + __MVGET ( DesignForm + 'OnMouseClick' )
		Code := Code + ' ON MOUSEDRAG ' + __MVGET ( DesignForm + 'OnMouseDrag' )
		Code := Code + ' ON MOUSEMOVE ' + __MVGET ( DesignForm + 'OnMouseMove' )
		Code := Code + ' ON SIZE ' + __MVGET ( DesignForm + 'OnSize' )
		Code := Code + ' ON MAXIMIZE ' + __MVGET ( DesignForm + 'OnMaximize' )
		Code := Code + ' ON MINIMIZE ' + __MVGET ( DesignForm + 'OnMinimize' )
		Code := Code + ' ON PAINT ' + __MVGET ( DesignForm + 'OnPaint' )

		if !Empty (__MVGET ( DesignForm + 'BackColor' ))
			Code := Code + ' BACKCOLOR ' + __MVGET ( DesignForm + 'BackColor' )
		Else
			Code := Code + ' BACKCOLOR NIL' 
		EndIf

		if !Empty (__MVGET ( DesignForm + 'NotifyIcon' ) )
			Code := Code + ' NOTIFYICON ' + chr(34) + __MVGET ( DesignForm + 'NotifyIcon' ) + chr(34)
		Else
			Code := Code + ' NOTIFYICON NIL' 
		EndIf

		if !Empty (__MVGET ( DesignForm + 'NotifyToolTip' ) )
			Code := Code + ' NOTIFYTOOLTIP ' + chr(34) + __MVGET ( DesignForm + 'NotifyToolTip' ) + chr(34)
		Else
			Code := Code + ' NOTIFYTOOLTIP NIL' 
		EndIf

		Code := Code + ' ON NOTIFYCLICK ' + __MVGET ( DesignForm + 'OnNotifyClick' )
		Code := Code + ' ON GOTFOCUS ' + __MVGET ( DesignForm + 'OnGotFocus' )
		Code := Code + ' ON LOSTFOCUS ' + __MVGET ( DesignForm + 'OnLostFocus' )
		Code := Code + ' ON SCROLLUP ' + __MVGET ( DesignForm + 'ONSCROLLUP' )
		Code := Code + ' ON SCROLLDOWN ' + __MVGET ( DesignForm + 'ONSCROLLDOWN' )
		Code := Code + ' ON SCROLLLEFT ' + __MVGET ( DesignForm + 'ONSCROLLLEFT' )
		Code := Code + ' ON SCROLLRIGHT ' + __MVGET ( DesignForm + 'ONSCROLLRIGHT' )
		Code := Code + ' ON HSCROLLBOX ' + __MVGET ( DesignForm + 'ONHSCROLLBOX' )
		Code := Code + ' ON VSCROLLBOX ' + __MVGET ( DesignForm + 'ONVSCROLLBOX' )

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'HelpButton' ) ) ) == '.T.'
			Code := Code + ' HELPBUTTON '
		EndIf

	ElseIf	WindowType == 'MODAL'

		Code := Code + 'DEFINE WINDOW TEMPLATE AT ' ;
		+ ALLTRIM(STR( GetProperty ( DesignForm , 'Row' ) )) ;
		+ ' , ' ;
		+  ALLTRIM(STR(GetProperty ( DesignForm , 'Col' ))) ;
		+ ' WIDTH ' ;
		+ ALLTRIM(STR(GetProperty ( DesignForm , 'Width' ))) ;
		+ ' HEIGHT ' ;
		+ ALLTRIM(STR(GetProperty ( DesignForm , 'Height' ))) ;
		+ ' VIRTUAL WIDTH ' ;
		+ ALLTRIM( __MVGET ( DesignForm + 'VirtualWidth' )) ;
		+ ' VIRTUAL HEIGHT ' ;
		+ ALLTRIM( __MVGET ( DesignForm + 'VirtualHeight' )) ;
		+ ' TITLE ' ;
		+ chr(34) + GetProperty ( DesignForm , 'Title' ) + chr(34) 

		if Empty (__MVGET ( DesignForm + 'Icon' ))
			Code := Code + ' ICON NIL'
		Else
			Code := Code + ' ICON ' + chr(34) + __MVGET ( DesignForm + 'Icon' ) + chr(34)
		EndIf

		Code := Code + ' MODAL' 

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'Visible' ) ) ) == '.F.' 
			Code := Code + ' NOSHOW'
		EndIf

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'AutoRelease' ) ) ) == '.F.' 
			Code := Code + ' NOAUTORELEASE'
		EndIf

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'Sizable' ) ) ) == '.F.' 
			Code := Code + ' NOSIZE'
		EndIf

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'SysMenu' ) ) ) == '.F.' 
			Code := Code + ' NOSYSMENU'
		EndIf

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'TitleBar' ) ) ) == '.F.' 
			Code := Code + ' NOCAPTION'
		EndIf

		if Empty (__MVGET ( DesignForm + 'Cursor' ))
			Code := Code + ' CURSOR NIL'
		Else
			Code := Code + ' CURSOR ' + chr(34) + __MVGET ( DesignForm + 'Cursor' ) + chr(34)
		EndIf

		Code := Code + ' ON INIT ' + __MVGET ( DesignForm + 'OnInit' )
		Code := Code + ' ON RELEASE ' + __MVGET ( DesignForm + 'OnRelease' )
		Code := Code + ' ON INTERACTIVECLOSE ' + __MVGET ( DesignForm + 'OnInteractiveClose' )
		Code := Code + ' ON MOUSECLICK ' + __MVGET ( DesignForm + 'OnMouseClick' )
		Code := Code + ' ON MOUSEDRAG ' + __MVGET ( DesignForm + 'OnMouseDrag' )
		Code := Code + ' ON MOUSEMOVE ' + __MVGET ( DesignForm + 'OnMouseMove' )
		Code := Code + ' ON SIZE ' + __MVGET ( DesignForm + 'OnSize' )
		Code := Code + ' ON PAINT ' + __MVGET ( DesignForm + 'OnPaint' )

		if !Empty (__MVGET ( DesignForm + 'BackColor' ))
			Code := Code + ' BACKCOLOR ' + __MVGET ( DesignForm + 'BackColor' )
		Else
			Code := Code + ' BACKCOLOR NIL' 
		EndIf

		Code := Code + ' ON GOTFOCUS ' + __MVGET ( DesignForm + 'OnGotFocus' )
		Code := Code + ' ON LOSTFOCUS ' + __MVGET ( DesignForm + 'OnLostFocus' )
		Code := Code + ' ON SCROLLUP ' + __MVGET ( DesignForm + 'ONSCROLLUP' )
		Code := Code + ' ON SCROLLDOWN ' + __MVGET ( DesignForm + 'ONSCROLLDOWN' )
		Code := Code + ' ON SCROLLLEFT ' + __MVGET ( DesignForm + 'ONSCROLLLEFT' )
		Code := Code + ' ON SCROLLRIGHT ' + __MVGET ( DesignForm + 'ONSCROLLRIGHT' )
		Code := Code + ' ON HSCROLLBOX ' + __MVGET ( DesignForm + 'ONHSCROLLBOX' )
		Code := Code + ' ON VSCROLLBOX ' + __MVGET ( DesignForm + 'ONVSCROLLBOX' )

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'HelpButton' ) ) ) == '.T.'
			Code := Code + ' HELPBUTTON '
		EndIf

	ElseIf	WindowType == 'SPLITCHILD'

		Code := Code + 'DEFINE WINDOW TEMPLATE ' ;
		+ ' WIDTH ' ;
		+ ALLTRIM(STR(GetProperty ( DesignForm , 'Width' ))) ;
		+ ' HEIGHT ' ;
		+ ALLTRIM(STR(GetProperty ( DesignForm , 'Height' ))) ;
		+ ' VIRTUAL WIDTH ' ;
		+ ALLTRIM( __MVGET ( DesignForm + 'VirtualWidth' )) ;
		+ ' VIRTUAL HEIGHT ' ;
		+ ALLTRIM( __MVGET ( DesignForm + 'VirtualHeight' )) ;
		+ ' TITLE ' ;
		+ chr(34) + GetProperty ( DesignForm , 'Title' ) + chr(34) ;
		+ ' SPLITCHILD' 

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'TitleBar' ) ) ) == '.F.' 
			Code := Code + ' NOCAPTION'
		EndIf

		if Empty (__MVGET ( DesignForm + 'Cursor' ))
			Code := Code + ' CURSOR NIL'
		Else
			Code := Code + ' CURSOR ' + chr(34) + __MVGET ( DesignForm + 'Cursor' ) + chr(34)
		EndIf

		if Empty (__MVGET ( DesignForm + 'GripperText' ))
			Code := Code + ' GRIPPERTEXT NIL'
		Else
			Code := Code + ' GRIPPERTEXT ' + chr(34) + __MVGET ( DesignForm + 'GripperText' ) + chr(34)
		EndIf

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'Break' ) ) ) == '.T.' 
			Code := Code + ' BREAK'
		EndIf

		if ALLTRIM ( HMG_UPPER (__MVGET ( DesignForm + 'Focused' ) ) ) == '.T.' 
			Code := Code + ' FOCUSED'
		EndIf

		Code := Code + ' ON GOTFOCUS ' + __MVGET ( DesignForm + 'OnGotFocus' )
		Code := Code + ' ON LOSTFOCUS ' + __MVGET ( DesignForm + 'OnLostFocus' )
		Code := Code + ' ON SCROLLUP ' + __MVGET ( DesignForm + 'ONSCROLLUP' )
		Code := Code + ' ON SCROLLDOWN ' + __MVGET ( DesignForm + 'ONSCROLLDOWN' )
		Code := Code + ' ON SCROLLLEFT ' + __MVGET ( DesignForm + 'ONSCROLLLEFT' )
		Code := Code + ' ON SCROLLRIGHT ' + __MVGET ( DesignForm + 'ONSCROLLRIGHT' )
		Code := Code + ' ON HSCROLLBOX ' + __MVGET ( DesignForm + 'ONHSCROLLBOX' )
		Code := Code + ' ON VSCROLLBOX ' + __MVGET ( DesignForm + 'ONVSCROLLBOX' )

	EndIf

	Code := Code + chr(13) + chr (10)

	If .Not. Empty(_hmgide_CurrentMainMenu  )
		Code := Code + chr(13) + chr (10)
		Code := Code + _hmgide_CurrentMainMenu 
	EndIf

	If .Not. Empty(_hmgide_CurrentToolBar )
		Code := Code + chr(13) + chr (10)
		Code := Code + _hmgide_CurrentToolBar 
	EndIf

	If .Not. Empty(_hmgide_CurrentContextMenu )
		Code := Code + chr(13) + chr (10)
		Code := Code + _hmgide_CurrentContextMenu 
	EndIf

	If .Not. Empty(_hmgide_CurrentStatusBar )
		Code := Code + chr(13) + chr (10)
		Code := Code + _hmgide_CurrentStatusBar 
	EndIf

	If .Not. Empty(_hmgide_CurrentNotifyMenu )
		Code := Code + chr(13) + chr (10)
		Code := Code + _hmgide_CurrentNotifyMenu 
	EndIf

	For b := 1 To HMG_LEN ( _hmgide_aDropDownMenus )

		If .Not. Empty ( _hmgide_aDropDownMenus [b] )
			Code := Code + chr(13) + chr (10)
			Code := Code + _hmgide_aDropDownMenus [b]
		EndIf

	Next b

	If .Not. Empty(_hmgide_CurrentSplitBox )
		Code := Code + chr(13) + chr (10)
		Code := Code + _hmgide_CurrentSplitBox 
	EndIf

        For i := 1 To HMG_LEN ( _HMG_SYSDATA [   3 ] )

		If _HMG_SYSDATA [   4 ] [i] == DesignFormhandle
		
			If !Empty (_HMG_SYSDATA [   2 ] [ i ] ) .and. HMG_UPPER(_HMG_SYSDATA [   2 ] [ i ] ) != 'INTERNAL_TIMER_1' .and.  HMG_UPPER(_HMG_SYSDATA [   2 ] [ i ] ) != 'TEXT_DUMMY' .and. _HMG_SYSDATA [ 13 ]  [i] ==  .F. 

				if _HMG_SYSDATA [ 23 ] [i] == -1 .and. _HMG_SYSDATA [ 24 ] [i] == -1 

					if _HMG_SYSDATA [ 1 ] [i] == 'TAB'

						Code := Code + CRLF + '    DEFINE TAB ' ;
							+ ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) ;
							+ ' AT ' ;
							+ ALLTRIM(STR( GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Row' ) )) ;
							+ ' , ' ;
							+  ALLTRIM(STR(GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Col' ))) ;
							+ ' WIDTH ' + ALLTRIM(STR(GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Width' ))) ;
							+ ' HEIGHT ' + ALLTRIM(STR(GetProperty ( DesignForm , ALLTRIM ( _HMG_SYSDATA [   2 ] [ i ] ) , 'Height' ))) ;
							+ ' VALUE ' + __MVGET( _HMG_SYSDATA [   2 ] [ i ]  + 'Value' ) ;
							+ ' FONT ' + chr(34) + __MVGET (_HMG_SYSDATA [   2 ] [ i ]  + 'FontName') + chr(34) ;
							+ ' SIZE ' + __MVGET (_HMG_SYSDATA [   2 ] [ i ]  + 'FontSize') ;
							+ IF ( ALLTRIM(HMG_UPPER(__MVGET(_HMG_SYSDATA [   2 ][i]+'FontBold'))) =='.T.',' BOLD','') ;
							+ IF ( ALLTRIM(HMG_UPPER(__MVGET(_HMG_SYSDATA [   2 ][i]+'FontItalic'))) =='.T.',' ITALIC','') ;
							+ IF ( ALLTRIM(HMG_UPPER(__MVGET(_HMG_SYSDATA [   2 ][i]+'FontUnderLine'))) =='.T.',' UNDERLINE','') ;
							+ IF ( ALLTRIM(HMG_UPPER(__MVGET(_HMG_SYSDATA [   2 ][i]+'FontStrikeOut'))) =='.T.',' STRIKEOUT','') ;
							+ ' TOOLTIP ' + chr(34) + __MVGET (_HMG_SYSDATA [   2 ] [ i ]  + 'ToolTip') + chr(34) ;
							+ IF ( ALLTRIM(HMG_UPPER(__MVGET(_HMG_SYSDATA [   2 ][i]+'Buttons'))) =='.T.',' BUTTONS','') ;
							+ IF ( ALLTRIM(HMG_UPPER(__MVGET(_HMG_SYSDATA [   2 ][i]+'Flat'))) =='.T.',' FLAT','') ;
							+ IF ( ALLTRIM(HMG_UPPER(__MVGET(_HMG_SYSDATA [   2 ][i]+'HotTrack'))) =='.T.',' HOTTRACK','') ;
							+ IF ( ALLTRIM(HMG_UPPER(__MVGET(_HMG_SYSDATA [   2 ][i]+'Vertical'))) =='.T.',' VERTICAL','') ;
							+ ' ON CHANGE ' + __MVGET( _HMG_SYSDATA [   2 ] [ i ]  + 'OnChange' ) ;
							+ IF ( ALLTRIM(HMG_UPPER(__MVGET(_HMG_SYSDATA [   2 ][i]+'TabStop'))) =='.F.',' NOTABSTOP','') ;
							+ IF ( ALLTRIM(HMG_UPPER(__MVGET(_HMG_SYSDATA [   2 ][i]+'Multiline'))) =='.T.',' MULTILINE','') ;
							+ CRLF

		                                PageMap := _HMG_SYSDATA [ 7 ] [i]
						
						For x := 1 To HMG_LEN ( PageMap )

							Code := Code + CRLF
							Code := Code + '        PAGE ' + chr(34) + _HMG_SYSDATA [ 33 ] [i] [x] + chr(34) 

							aTemp := StringToArray ( __MVGET( _HMG_SYSDATA [   2 ] [ i ]  + 'PageImages' ) )

							ImageFlag := .F.

							For a := 1 To HMG_LEN (aTemp)
								If !Empty(aTemp[a])
									ImageFlag := .T.
									Exit								
								EndIf
							Next a
							
							if ImageFlag == .T.

								Code := Code + ' IMAGE ' + chr(34) + aTemp [x] + chr(34) + CRLF

							else

								Code := Code + CRLF 

							endif

							For j := 1 To HMG_LEN ( PageMap [x] )

								if VALTYPE (PageMap [x] [j]) == 'N'
									idx := ascan ( _HMG_SYSDATA [   3 ] , PageMap [x] [j] )
									Code := Code + GenCode (idx , .t. )
						
								Elseif VALTYPE (PageMap [x] [j]) == 'A'

									for k := 1 To HMG_LEN ( _HMG_SYSDATA [   3 ] )

										if VALTYPE ( _HMG_SYSDATA [   3 ] [k] )	== 'A'

											if _HMG_SYSDATA [   3 ] [k] [1]	== PageMap [x] [j] [1]

												Code := Code + GenCode (k , .t. )
												Exit

											endif		

										endif

									next k

								endif

							Next j

							Code := Code + CRLF
							Code := Code + '        END PAGE ' + CRLF

						Next x

						Code := Code + CRLF
						Code := Code + '    END TAB ' + CRLF

					Else

						Code := Code + GenCode (i,.f.)

					EndIf

				endif

			EndIf

		EndIf

	Next i

	Code := Code + '' + CRLF
	Code := Code + 'END WINDOW' + chr(13) + chr (10)
	Code := Code + '' + CRLF

	if VALTYPE ( lView ) == 'L' .and. lView == .T.

		RetVal := Code

	Else

		If HMG_UPPER ( HB_URIGHT ( ALLTRIM(OpenFormName) , 4 ) ) != '.FMG'
			OpenFormName := ALLTRIM(OpenFormName) + '.fmg'
		EndIf

		SaveString ( OpenFormName , Code )
		DesignFormModified := .F.

	EndIf

RETURN RetVal