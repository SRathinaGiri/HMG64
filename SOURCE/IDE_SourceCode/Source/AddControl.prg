*------------------------------------------------------------------------------*
PROCEDURE AddControl()
*------------------------------------------------------------------------------*
LOCAL VDC, VDR, ControlName, fmb, TMPBUTTONS
Local aName
Local ControlRow  
Local ControlCol
Local i
Local ControlWidth 
Local ControlHeight 
Local dr
Local dc
Local x
Local HitTestOk 
Local SupMin
Local TabName
Local TabPage
Local TabRow
Local TabCol
Local TabIndex 
Local TabWidth
Local TabHeight 
Local TabCaptions
Local SupMinName
Local TabFlat
Local f
Local z
Local y
Local aNames
Local aProperties
Local aEvents	
Local apValues
Local aeValues


Private macrovar

	DesignFormModified := .T.

	If MoveStarted == .T.

		MoveStarted := .F.

		SetProperty ( DesignForm , _HMG_SYSDATA [   2 ] [moveindex] , 'Row' , _HMG_SYSDATA [ 191 ] )
		SetProperty ( DesignForm , _HMG_SYSDATA [   2 ] [moveindex] , 'Col' , _HMG_SYSDATA [ 192 ] )
		SetProperty ( DesignForm , _HMG_SYSDATA [   2 ] [moveindex] , 'Visible' , .T. )

		SelectControl ( _HMG_SYSDATA [   2 ] [ MoveIndex ] )

		RETURN

	EndIf

	If SizeStarted == .T.

		SizeStarted := .F.

		SetProperty ( DesignForm , _HMG_SYSDATA [   2 ] [moveindex] , 'Width' , _HMG_SYSDATA [ 192 ] - MoveCol )
		SetProperty ( DesignForm , _HMG_SYSDATA [   2 ] [moveindex] , 'Height' , _HMG_SYSDATA [ 191 ] - MoveRow )
		SetProperty ( DesignForm , _HMG_SYSDATA [   2 ] [moveindex] , 'Visible' , .T. )

		SelectControl ( _HMG_SYSDATA [   2 ] [ MoveIndex ] )

		RETURN

	EndIf

	if CurrentControl >= 2 .and. CurrentControl <= 27

		If SnapToGrid == .T.

			dr := 10 - VAL ( HB_URIGHT ( ALLTRIM( STR ( _HMG_SYSDATA [ 191 ] ) ) , 1 ) )
			_HMG_SYSDATA [ 191 ] := _HMG_SYSDATA [ 191 ] + dr

			dc := 10 - VAL ( HB_URIGHT ( ALLTRIM( STR ( _HMG_SYSDATA [ 192 ] ) ) , 1 ) )
			_HMG_SYSDATA [ 192 ] := _HMG_SYSDATA [ 192 ] + dc

		EndIf

	EndIf

	if form_main.user.value <> 0
		CurrentControl := 99
	endif

	Do Case

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 99
	///////////////////////////////////////////////////////////////////////

		f := form_main.user.value

		If f == 0
			RETURN
		EndIf

	
		__MVPUT ( aComponentNames [ f ] + 'Count' ,  __MVGET ( aComponentNames [ f ] + 'Count' ) + 1 )

		ControlName := aComponentNames [ f ] + '_' + ALLTRIM(STR( __MVGET ( aComponentNames [ f ] + 'Count' ) ) )

		Do While _IsControlDefined (ControlName,DesignForm)

			__MVPUT ( aComponentNames [ f ] + 'Count' ,  __MVGET ( aComponentNames [ f ] + 'Count' ) + 1 )

			ControlName := aComponentNames [ f ] + '_' + ALLTRIM(STR( __MVGET ( aComponentNames [ f ] + 'Count' ) ) )

		EndDo

		@ _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] LABEL &ControlName ;
			OF &DesignForm ;
			VALUE ControlName ACTION SelectControl (This.Name) ;
			WIDTH 150 HEIGHT 150 ;
			FONT 'ARIAL' SIZE 9 ;
			BORDER

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		_HMG_SYSDATA [ 39 ] [ GetControlIndex ( ControlName , DesignForm ) ] := 10 + f 

		z := _HMG_SYSDATA [ 39 ] [ GetControlIndex ( ControlName , DesignForm ) ] - 10

		aNames		:= aComponentNames	[z]
		aProperties	:= aComponentProperties	[z]
		aEvents		:= aComponentEvents	[z]
		apValues	:= aComponentPropValues [z]
		aeValues	:= aComponentEvtValues  [z]

		For y := 1 To HMG_LEN ( aProperties )

			If	HMG_UPPER( ALLTRIM( aProperties[y] ) ) <> 'NAME'

				__MVPUBLIC ( ControlName + aProperties [y] ) 
				__MVPUT( ControlName + aProperties [y] , apValues [y] )

			EndIf

		Next y

		SetProperty ( DesignForm , ControlName , "Width"  , VAL ( __MVGET ( ControlName + "Width"  ) ) )
		SetProperty ( DesignForm , ControlName , "Height" , VAL ( __MVGET ( ControlName + "Height" ) ) )

		For y := 1 To HMG_LEN ( aEvents )

			__MVPUBLIC ( ControlName + aEvents [y] ) 
			__MVPUT( ControlName + aEvents [y] , aeValues [y] )

		Next y




	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 1
	///////////////////////////////////////////////////////////////////////

	        For i := 1 To HMG_LEN ( _HMG_SYSDATA [   3 ] )

			If _HMG_SYSDATA [   4 ] [i] == DesignFormhandle

				If  !Empty (_HMG_SYSDATA [   2 ] [ i ] ) .and. HMG_UPPER(_HMG_SYSDATA [   2 ] [ i ] ) != 'INTERNAL_TIMER_1' .and.  HMG_UPPER(_HMG_SYSDATA [   2 ] [ i ] ) != 'TEXT_DUMMY'  .and. _HMG_SYSDATA [ 13 ]  [i] ==  .F. 

				ControlRow := _HMG_SYSDATA [ 18 ] [i] 
				ControlCol := _HMG_SYSDATA [ 19 ] [i] 

				ControlWidth := _HMG_SYSDATA [ 20 ] [i] 
				ControlHeight := _HMG_SYSDATA [ 21 ] [i] 

				// Move

				If	( _HMG_SYSDATA [ 191 ] >= ControlRow -16 .and. _HMG_SYSDATA [ 191 ] <= ControlRow ) ;
					.and. ;
					( _HMG_SYSDATA [ 192 ] >= ControlCol -16 .and. _HMG_SYSDATA [ 192 ] <= ControlCol )

					if _HMG_SYSDATA [   2 ] [i] == SelectedControlName .and. ! Empty(SelectedControlName)

						Form_Main.StatusBar.Item (3 + STATUSITEM_OFFSET) := ''

						MoveCol		:= ControlCol
						MoveRow		:= ControlRow
						MoveWidth	:= _HMG_SYSDATA [ 20 ] [i]
						MoveHeight	:= _HMG_SYSDATA [ 21 ] [i]
						MoveIndex 	:= i

						SetProperty ( DesignForm , 'Cursor' , 'Hand' )

						SetProperty ( DesignForm , _HMG_SYSDATA [   2 ] [i] , 'Visible' , .F. )

						MoveStarted := .T.

						If SnapToGrid == .T.

							dr := 10 - VAL ( HB_URIGHT ( ALLTRIM( STR ( _HMG_SYSDATA [ 191 ] ) ) , 1 ) )
							_HMG_SYSDATA [ 191 ] := _HMG_SYSDATA [ 191 ] + dr

							dc := 10 - VAL ( HB_URIGHT ( ALLTRIM( STR ( _HMG_SYSDATA [ 192 ] ) ) , 1 ) )
							_HMG_SYSDATA [ 192 ] := _HMG_SYSDATA [ 192 ] + dc

						EndIf

						_pr := _HMG_SYSDATA [ 191 ]
						_pc := _HMG_SYSDATA [ 192 ]

						Exit

					endif

				EndIf

				// Size

				If	( _HMG_SYSDATA [ 191 ] >= ControlRow + ControlHeight .and. _HMG_SYSDATA [ 191 ] <= ControlRow + ControlHeight + 16 ) ;
					.and. ;
					( _HMG_SYSDATA [ 192 ] >= ControlCol + ControlWidth .and. _HMG_SYSDATA [ 192 ] <= ControlCol + ControlWidth + 16 )

					If _HMG_SYSDATA [ 1 ] [ i ] = 'MONTHCAL'
						Exit
					EndIf
					If _HMG_SYSDATA [ 1 ] [ i ] = 'BUTTON' .and. _HMG_SYSDATA [ 39 ] [ i ] == 5
						Exit
					EndIf

					if _HMG_SYSDATA [   2 ] [i] == SelectedControlName .and. ! Empty(SelectedControlName)

						Form_Main.StatusBar.Item (3 + STATUSITEM_OFFSET) := ''

						MoveCol		:= ControlCol
						MoveRow		:= ControlRow
						MoveWidth	:= _HMG_SYSDATA [ 20 ] [i]
						MoveHeight	:= _HMG_SYSDATA [ 21 ] [i]
						MoveIndex 	:= i

						SetProperty ( DesignForm , 'Cursor' , 'Size' )

						SetProperty ( DesignForm , _HMG_SYSDATA [   2 ] [i] , 'Visible' , .F. )          
		
						SizeStarted := .T.

						_pr := _HMG_SYSDATA [ 191 ]
						_pc := _HMG_SYSDATA [ 192 ]
					
						Exit

					endif

				EndIf

				EndIf

			EndIf

		Next i

		***

		SupMin := 999999999
		SupMinName := ''

		HitTestOk := .F.

		if MoveStarted == .f. .and. SizeStarted == .f.

		        For i := 1 To HMG_LEN ( _HMG_SYSDATA [   3 ] )
				If _HMG_SYSDATA [   4 ] [i] == DesignFormhandle
					If  !Empty (_HMG_SYSDATA [   2 ] [ i ] ) .and. HMG_UPPER(_HMG_SYSDATA [   2 ] [ i ] ) != 'INTERNAL_TIMER_1' .and.  HMG_UPPER(_HMG_SYSDATA [   2 ] [ i ] ) != 'TEXT_DUMMY'  .and. _HMG_SYSDATA [ 13 ]  [i] ==  .F. 

						If _HMG_SYSDATA [ 1 ] [ i ] == 'FRAME' .OR. _HMG_SYSDATA [ 1 ] [ i ] == 'TAB' .OR. _HMG_SYSDATA [ 1 ] [ i ] == 'ANIMATEBOX'

							ControlRow := _HMG_SYSDATA [ 18 ] [i] 
							ControlCol := _HMG_SYSDATA [ 19 ] [i] 
							ControlWidth := _HMG_SYSDATA [ 20 ] [i] 
							ControlHeight := _HMG_SYSDATA [ 21 ] [i] 

							if HitTest( _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] , ControlRow , ControlCol , ControlWidth , ControlHeight ) == .T.
								if ( ControlWidth * ControlHeight ) < SupMin

									if IsFrameActive(i) == .T.

										SupMin := ControlWidth * ControlHeight
										SupMinName := _HMG_SYSDATA [   2 ] [i]
										HitTestOk := .T.
										/*
										if _HMG_SYSDATA [ 1 ] [i] == 'TAB'
										        cTemp := '{ '
											For j := 1 To HMG_LEN ( _HMG_SYSDATA [ 33 ] [i] )			
												cTemp := cTemp + chr(34) + _HMG_SYSDATA [ 33 ] [i] [j] + chr(34) + ' , '
											Next j
									                cTemp := ALLTRIM (cTemp)
											cTemp := HB_ULEFT ( cTemp , HMG_LEN(cTemp) - 1 )
											cTemp := cTemp + '} '	
											__MVPUT (_HMG_SYSDATA [   2 ] [i] + 'Captions' , cTemp )
											__MVPUT (_HMG_SYSDATA [   2 ] [i] + 'PageCount' , ALLTRIM(STR(HMG_LEN(_HMG_SYSDATA [ 7 ][i]))) )
										endif
		                                                                */
									
									endif

								endif

							EndIf
		
						EndIf				

					EndIf

				EndIf

			Next i	

		endif

		if HitTestOk == .T.

			SelectControl ( SupMinName )

		EndIf
		***

		if MoveStarted == .f. .and. SizeStarted == .f. .and. HitTestOk == .F.

			If .not. empty(SelectedControlName)
				x := GetControlIndex (SelectedControlName, DesignForm )
				If x > 0

					if lVirtualForm
						VDC := GetScrollPos ( DesignFormhandle , SB_HORZ )  
						VDR := GetScrollPos ( DesignFormhandle , SB_VERT )  
					else
						VDC := 0
						VDR := 0
					endif

					RedrawRect ( DesignFormhandle , _HMG_SYSDATA [ 18 ] [x] - 10 - VDR, _HMG_SYSDATA [ 19 ] [x] - 10 - VDC , _HMG_SYSDATA [ 18 ] [x]+_HMG_SYSDATA [ 21 ] [x]+10 - VDR , _HMG_SYSDATA [ 19 ] [x]+_HMG_SYSDATA [ 20 ] [x]+10 - VDC )
				EndIf
			EndIf

			UpdateDesignFormProperties()
			Properties.Combo_1.Value := 1

			SelectedControlname := ''

		EndIf

		DrawGrid()

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 2
	///////////////////////////////////////////////////////////////////////
		ButtonCount++
		ControlName := 'Button_'+ALLTRIM(STR(ButtonCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			ButtonCount++
			ControlName := 'Button_'+ALLTRIM(STR(ButtonCount))
		EndDo
        
		@ _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] BUTTON &ControlName OF &DesignForm CAPTION ControlName FONT 'Arial' SIZE 9 ACTION dummy() ON GOTFOCUS SelectControl( This.Name )

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		__MVPUBLIC ( ControlName + 'Caption' ) 
		__MVPUT( ControlName + 'Caption' , ControlName )
		__MVPUBLIC ( ControlName + 'Action' ) 
		__MVPUT( ControlName + 'Action' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'OnGotFocus' ) 
		__MVPUT( ControlName + 'OnGotFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnLostFocus' ) 
		__MVPUT( ControlName + 'OnLostFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'Flat' ) 
		__MVPUT( ControlName + 'Flat' , '.F.' )
		__MVPUBLIC ( ControlName + 'TabStop' ) 
		__MVPUT( ControlName + 'TabStop' , '.T.' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Transparent' ) 
		__MVPUT( ControlName + 'Transparent' , '.F.' )
		__MVPUBLIC ( ControlName + 'Picture' ) 
		__MVPUT( ControlName + 'Picture' , '' )
		__MVPUBLIC ( ControlName + 'PictAlignMent' ) 
		__MVPUT( ControlName + 'PictAlignment' , 'TOP' )
		__MVPUBLIC ( ControlName + 'MultiLine' ) 
		__MVPUT( ControlName + 'MultiLine' , '.F.' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 3
	///////////////////////////////////////////////////////////////////////
		CheckBoxCount++
		ControlName := 'Check_'+ALLTRIM(STR(CheckBoxCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			CheckBoxCount++
			ControlName := 'Check_'+ALLTRIM(STR(CheckBoxCount))
		EndDo

		TabName := TabHit( _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] )

		if ! empty ( TabName )
			fmb := _HMG_SYSDATA [ 183 ]
			_HMG_SYSDATA [ 183 ] := 1
			_HMG_SYSDATA [ 225 ]  := TabName
			_HMG_SYSDATA [ 332 ] [_HMG_SYSDATA [ 183 ]] := DesignForm
		endif

		if ! empty ( TabName )
			_HMG_SYSDATA [ 266 ] := _HMG_SYSDATA [ 31 ] [ GetControlIndex ( TabName , DesignForm ) ]  
		endif

		@ _HMG_SYSDATA [ 191 ],_HMG_SYSDATA [ 192 ] CHECKBOX &ControlName OF &DesignForm CAPTION ControlName FONT 'Arial' SIZE 9 On Change SelectControl (This.Name)

		if ! empty ( TabName )
			_HMG_SYSDATA [ 183 ] := fmb
		endif

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		if ! empty ( TabName )
			_HMG_SYSDATA [ 16 ] [ GetControlIndex ( ControlName , DesignForm ) ] := _HMG_SYSDATA [ 31 ]  [ GetControlIndex ( TabName , DesignForm ) ] 
		endif

		__MVPUBLIC ( ControlName + 'Caption' ) 
		__MVPUT( ControlName + 'Caption' , ControlName )
		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'OnChange' ) 
		__MVPUT( ControlName + 'OnChange' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnGotFocus' ) 
		__MVPUT( ControlName + 'OnGotFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnLostFocus' ) 
		__MVPUT( ControlName + 'OnLostFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'Field' ) 
		__MVPUT( ControlName + 'Field' , 'Nil' )
		__MVPUBLIC ( ControlName + 'BackColor' ) 
		__MVPUT( ControlName + 'BackColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontColor' ) 
		__MVPUT( ControlName + 'FontColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'TabStop' ) 
		__MVPUT( ControlName + 'TabStop' , '.T.' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Transparent' ) 
		__MVPUT( ControlName + 'Transparent' , '.F.' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 4
	///////////////////////////////////////////////////////////////////////
		ListBoxCount++
		ControlName := 'List_'+ALLTRIM(STR(ListBoxCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			ListBoxCount++
			ControlName := 'List_'+ALLTRIM(STR(ListBoxCount))
		EndDo

		aName := { ControlName }
		@ _HMG_SYSDATA [ 191 ],_HMG_SYSDATA [ 192 ] LISTBOX &ControlName OF &DesignForm WIDTH 100 HEIGHT 100 ITEMS aName FONT 'Arial' SIZE 9 ON GOTFOCUS SelectControl ( This.Name )

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		__MVPUBLIC ( ControlName + 'Items' ) 
		__MVPUT( ControlName + 'Items' , '{""}' )
		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , '0' )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'OnChange' ) 
		__MVPUT( ControlName + 'OnChange' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnGotFocus' ) 
		__MVPUT( ControlName + 'OnGotFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnLostFocus' ) 
		__MVPUT( ControlName + 'OnLostFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'BackColor' ) 
		__MVPUT( ControlName + 'BackColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontColor' ) 
		__MVPUT( ControlName + 'FontColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnDblClick' ) 
		__MVPUT( ControlName + 'OnDblClick' , 'Nil' )
		__MVPUBLIC ( ControlName + 'TabStop' ) 
		__MVPUT( ControlName + 'TabStop' , '.T.' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Sort' ) 
		__MVPUT( ControlName + 'Sort' , '.F.' )
		__MVPUBLIC ( ControlName + 'MultiSelect' ) 
		__MVPUT( ControlName + 'MultiSelect' , '.F.' )
		__MVPUBLIC ( ControlName + 'DragItems' ) 
		__MVPUT( ControlName + 'DragItems' , '.F.' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 5
	///////////////////////////////////////////////////////////////////////
		ComboBoxCount++
		ControlName := 'Combo_'+ALLTRIM(STR(ComboBoxCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			ComboBoxCount++
			ControlName := 'Combo_'+ALLTRIM(STR(ComboBoxCount))
		EndDo

		aName := { ControlName }
		@ _HMG_SYSDATA [ 191 ],_HMG_SYSDATA [ 192 ] COMBOBOX &ControlName OF &DesignForm WIDTH 100 HEIGHT 100 ITEMS aName VALUE 1 FONT 'Arial' SIZE 9 ON GOTFOCUS SelectControl ( This.Name )

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		__MVPUBLIC ( ControlName + 'Items' ) 
		__MVPUT( ControlName + 'Items' , '{""}' )
		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , '0' )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'OnChange' ) 
		__MVPUT( ControlName + 'OnChange' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnGotFocus' ) 
		__MVPUT( ControlName + 'OnGotFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnLostFocus' ) 
		__MVPUT( ControlName + 'OnLostFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'TabStop' ) 
		__MVPUT( ControlName + 'TabStop' , '.T.' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Sort' ) 
		__MVPUT( ControlName + 'Sort' , '.F.' )
		__MVPUBLIC ( ControlName + 'OnEnter' ) 
		__MVPUT( ControlName + 'OnEnter' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnDisplayChange' ) 
		__MVPUT( ControlName + 'OnDisplayChange' , 'Nil' )
		__MVPUBLIC ( ControlName + 'DisplayEdit' ) 
		__MVPUT( ControlName + 'DisplayEdit' , '.F.' )
		__MVPUBLIC ( ControlName + 'ItemSource' ) 
		__MVPUT( ControlName + 'ItemSource' , 'Nil' )
		__MVPUBLIC ( ControlName + 'ValueSource' ) 
		__MVPUT( ControlName + 'ValueSource' , '' )

		__MVPUBLIC ( ControlName + 'Image' ) 
		__MVPUT( ControlName + 'Image' , 'Nil' )

		__MVPUBLIC ( ControlName + 'DroppedWidth' ) 
		__MVPUT( ControlName + 'DroppedWidth' , 'Nil' )

		__MVPUBLIC ( ControlName + 'OnDropDown' ) 
		__MVPUT( ControlName + 'OnDropDown' , 'Nil' )

		__MVPUBLIC ( ControlName + 'OnCloseUp' ) 
		__MVPUT( ControlName + 'OnCloseUp' , 'Nil' )


	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 6
	///////////////////////////////////////////////////////////////////////
		CheckButtonCount++
		ControlName := 'CheckBtn_'+ALLTRIM(STR(CheckButtonCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			CheckButtonCount++
			ControlName := 'CheckBtn_'+ALLTRIM(STR(CheckButtonCount))
		EndDo

		@ _HMG_SYSDATA [ 191 ],_HMG_SYSDATA [ 192 ] CHECKBUTTON &ControlName OF &DesignForm CAPTION ControlName FONT 'Arial' SIZE 9 ON CHANGE SelectControl (This.name)

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		_HMG_SYSDATA [ 39 ] [ GetControlIndex ( ControlName , DesignForm ) ] := 1

		__MVPUBLIC ( ControlName + 'Caption' ) 
		__MVPUT( ControlName + 'Caption' , ControlName )
		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'OnChange' ) 
		__MVPUT( ControlName + 'OnChange' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnGotFocus' ) 
		__MVPUT( ControlName + 'OnGotFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnLostFocus' ) 
		__MVPUT( ControlName + 'OnLostFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'TabStop' ) 
		__MVPUT( ControlName + 'TabStop' , '.T.' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Picture' ) 
		__MVPUT( ControlName + 'Picture' , '' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 7
	///////////////////////////////////////////////////////////////////////
		GridCount++
		ControlName := 'Grid_'+ALLTRIM(STR(GridCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			GridCount++
			ControlName := 'Grid_'+ALLTRIM(STR(GridCount))
		EndDo

		aName := { { ControlName } }
		@ _HMG_SYSDATA [ 191 ],_HMG_SYSDATA [ 192 ] GRID &ControlName OF &DesignForm WIDTH 120 HEIGHT 120 HEADERS {''} WIDTHS {100} ITEMS aName FONT 'Arial' SIZE 9 ON GOTFOCUS SelectControl(This.name)

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		__MVPUBLIC ( ControlName + 'Items' ) 
		__MVPUT( ControlName + 'Items' , '{ {""} }' )
		__MVPUBLIC ( ControlName + 'Headers' ) 
		__MVPUT( ControlName + 'Headers' , "{''}" )
		__MVPUBLIC ( ControlName + 'Widths' ) 
		__MVPUT( ControlName + 'Widths' , "{ 0 }" )
		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'OnChange' ) 
		__MVPUT( ControlName + 'OnChange' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnGotFocus' ) 
		__MVPUT( ControlName + 'OnGotFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnLostFocus' ) 
		__MVPUT( ControlName + 'OnLostFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'OnDblClick' ) 
		__MVPUT( ControlName + 'OnDblClick' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnHeadClick' ) 
		__MVPUT( ControlName + 'OnHeadClick' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnQueryData' ) 
		__MVPUT( ControlName + 'OnQueryData' , 'Nil' )
		__MVPUBLIC ( ControlName + 'MultiSelect' ) 
		__MVPUT( ControlName + 'MultiSelect' , '.F.' )
		__MVPUBLIC ( ControlName + 'AllowEdit' ) 
		__MVPUT( ControlName + 'AllowEdit' , '.F.' )
		__MVPUBLIC ( ControlName + 'Virtual' ) 
		__MVPUT( ControlName + 'Virtual' , '.F.' )
		__MVPUBLIC ( ControlName + 'Lines' ) 
		__MVPUT( ControlName + 'Lines' , '.T.' )
		__MVPUBLIC ( ControlName + 'Image' ) 
		__MVPUT( ControlName + 'Image' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Justify' ) 
		__MVPUT( ControlName + 'Justify' , 'Nil' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'ItemCount' ) 
		__MVPUT( ControlName + 'ItemCount' , 'Nil' )
		__MVPUBLIC ( ControlName + 'BackColor' ) 
		__MVPUT( ControlName + 'BackColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontColor' ) 
		__MVPUT( ControlName + 'FontColor' , 'Nil' )

		* 2.0

		__MVPUBLIC ( ControlName + 'DynamicBackColor' ) 
		__MVPUT( ControlName + 'DynamicBackColor' , 'Nil' )

		__MVPUBLIC ( ControlName + 'DynamicForeColor' ) 
		__MVPUT( ControlName + 'DynamicForeColor' , 'Nil' )

		__MVPUBLIC ( ControlName + 'ColumnWhen' ) 
		__MVPUT( ControlName + 'ColumnWhen' , 'Nil' )

		__MVPUBLIC ( ControlName + 'ColumnValid' ) 
		__MVPUT( ControlName + 'ColumnValid' , 'Nil' )

		__MVPUBLIC ( ControlName + 'ColumnControls' ) 
		__MVPUT( ControlName + 'ColumnControls' , 'Nil' )

		__MVPUBLIC ( ControlName + 'ShowHeaders' ) 
		__MVPUT( ControlName + 'ShowHeaders' , '.T.' )

		__MVPUBLIC ( ControlName + 'HeaderImages' ) 
		__MVPUT( ControlName + 'HeaderImages' , 'Nil' )

		__MVPUBLIC ( ControlName + 'CellNavigation' ) 
		__MVPUT( ControlName + 'CellNavigation' , '.F.' )

		* _._

		__MVPUBLIC ( ControlName + 'RowSource' ) 
		__MVPUT( ControlName + 'RowSource' , 'Nil' )

		__MVPUBLIC ( ControlName + 'ColumnFields' ) 
		__MVPUT( ControlName + 'ColumnFields' , 'Nil' )

		__MVPUBLIC ( ControlName + 'AllowAppend' ) 
		__MVPUT( ControlName + 'AllowAppend' , '.F.' )

		__MVPUBLIC ( ControlName + 'AllowDelete' ) 
		__MVPUT( ControlName + 'AllowDelete' , '.F.' )

		__MVPUBLIC ( ControlName + 'Buffered' ) 
		__MVPUT( ControlName + 'Buffered' , '.F.' )

		__MVPUBLIC ( ControlName + 'DynamicDisplay' ) 
		__MVPUT( ControlName + 'DynamicDisplay' , 'Nil' )

		__MVPUBLIC ( ControlName + 'OnSave' ) 
		__MVPUT( ControlName + 'OnSave' , 'Nil' )

		__MVPUBLIC ( ControlName + 'LockColumns' ) 
		__MVPUT( ControlName + 'LockColumns' , 'Nil' )


	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 8
	///////////////////////////////////////////////////////////////////////
		SliderCount++
		ControlName := 'Slider_'+ALLTRIM(STR(SliderCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			SliderCount++
			ControlName := 'Slider_'+ALLTRIM(STR(SliderCount))
		EndDo

		TabName := TabHit( _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] )

		if ! empty ( TabName )
			fmb := _HMG_SYSDATA [ 183 ]
			_HMG_SYSDATA [ 183 ] := 1
			_HMG_SYSDATA [ 225 ]  := TabName
			_HMG_SYSDATA [ 332 ] [_HMG_SYSDATA [ 183 ]] := DesignForm
		endif

		if ! empty ( TabName )
			_HMG_SYSDATA [ 266 ] := _HMG_SYSDATA [ 31 ] [ GetControlIndex ( TabName , DesignForm ) ]  
		endif

		@ _HMG_SYSDATA [ 191 ],_HMG_SYSDATA [ 192 ] SLIDER &ControlName OF &DesignForm RANGE 1,10 VALUE 5 ON CHANGE SelectControl (This.Name)

		if ! empty ( TabName )
			_HMG_SYSDATA [ 183 ] := fmb
		endif

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		if ! empty ( TabName )
			_HMG_SYSDATA [ 16 ] [ GetControlIndex ( ControlName , DesignForm ) ] := _HMG_SYSDATA [ 31 ]  [ GetControlIndex ( TabName , DesignForm ) ] 
		endif

		SetFocus ( GetControlhandle ( ControlName , DesignForm ) )

		__MVPUBLIC ( ControlName + 'RangeMin' ) 
		__MVPUT( ControlName + 'RangeMin' , '1' )
		__MVPUBLIC ( ControlName + 'RangeMax' ) 
		__MVPUT( ControlName + 'RangeMax' , '10' )
		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , '0' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'OnChange' ) 
		__MVPUT( ControlName + 'OnChange' , 'Nil' )
		__MVPUBLIC ( ControlName + 'TabStop' ) 
		__MVPUT( ControlName + 'TabStop' , '.T.' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'TickMarks' ) 
		__MVPUT( ControlName + 'TickMarks' , 'BOTTOM' )
		__MVPUBLIC ( ControlName + 'Orientation' ) 
		__MVPUT( ControlName + 'Orientation' , 'HORIZONTAL' )
		__MVPUBLIC ( ControlName + 'BackColor' ) 
		__MVPUT( ControlName + 'BackColor' , 'Nil' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 9
	///////////////////////////////////////////////////////////////////////
		SpinnerCount++
		ControlName := 'Spinner_'+ALLTRIM(STR(SpinnerCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			SpinnerCount++
			ControlName := 'Spinner_'+ALLTRIM(STR(SpinnerCount))
		EndDo

		DEFINE SPINNER &ControlName
			PARENT &DesignForm
			ROW _HMG_SYSDATA [ 191 ]
			COL _HMG_SYSDATA [ 192 ]
			VALUE 5
			RANGEMIN 1
			RANGEMAX 10
			ON GOTFOCUS SelectControl (This.Name)
			FONTNAME 'ARIAL'
			FONTSIZE 9
		END SPINNER

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		__MVPUBLIC ( ControlName + 'RangeMin' ) 
		__MVPUT( ControlName + 'RangeMin' , '1' )
		__MVPUBLIC ( ControlName + 'RangeMax' ) 
		__MVPUT( ControlName + 'RangeMax' , '10' )
		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , '0' )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'OnChange' ) 
		__MVPUT( ControlName + 'OnChange' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnGotFocus' ) 
		__MVPUT( ControlName + 'OnGotFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnLostFocus' ) 
		__MVPUT( ControlName + 'OnLostFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'TabStop' ) 
		__MVPUT( ControlName + 'TabStop' , '.T.' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'BackColor' ) 
		__MVPUT( ControlName + 'BackColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontColor' ) 
		__MVPUT( ControlName + 'FontColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Wrap' ) 
		__MVPUT( ControlName + 'Wrap' , '.F.' )
		__MVPUBLIC ( ControlName + 'ReadOnly' ) 
		__MVPUT( ControlName + 'ReadOnly' , '.F.' )
		__MVPUBLIC ( ControlName + 'Increment' ) 
		__MVPUT( ControlName + 'Increment' , '1' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 10
	///////////////////////////////////////////////////////////////////////
		ImageCount++
		ControlName := 'Image_'+ALLTRIM(STR(ImageCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			ImageCount++
			ControlName := 'Image_'+ALLTRIM(STR(ImageCount))
		EndDo

		DEFINE IMAGE &ControlName
			PARENT &DesignForm
			ROW _HMG_SYSDATA [ 191 ]
			COL _HMG_SYSDATA [ 192 ]
			WIDTH 123
			HEIGHT 123 
			ACTION SelectControl (This.name)
			PICTURE 'demo'
			STRETCH .T.
		END IMAGE

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		__MVPUBLIC ( ControlName + 'Picture' ) 
		__MVPUT( ControlName + 'Picture' , '' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Stretch' ) 
		__MVPUT( ControlName + 'Stretch' , '.F.' )
		__MVPUBLIC ( ControlName + 'Action' ) 
		__MVPUT( ControlName + 'Action' , 'Nil' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 11
	///////////////////////////////////////////////////////////////////////

		TreeCount++
		ControlName := 'Tree_'+ALLTRIM(STR(TreeCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			TreeCount++
			ControlName := 'Tree_'+ALLTRIM(STR(TreeCount))
		EndDo


		DEFINE TREE &ControlName ;
			OF &DesignForm ;
			AT _HMG_SYSDATA [ 191 ],_HMG_SYSDATA [ 192 ] ;
			TOOLTIP ControlName ;
			ON GOTFOCUS SelectControl(This.Name)
			
			NODE ControlName
			END NODE

		END TREE

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , '0' )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'OnChange' ) 
		__MVPUT( ControlName + 'OnChange' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnGotFocus' ) 
		__MVPUT( ControlName + 'OnGotFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnLostFocus' ) 
		__MVPUT( ControlName + 'OnLostFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'OnDblClick' ) 
		__MVPUT( ControlName + 'OnDblClick' , 'Nil' )
		__MVPUBLIC ( ControlName + 'NodeImages' ) 
		__MVPUT( ControlName + 'NodeImages' , 'Nil' )
		__MVPUBLIC ( ControlName + 'ItemImages' ) 
		__MVPUT( ControlName + 'ItemImages' , 'Nil' )
		__MVPUBLIC ( ControlName + 'RootButton' ) 
		__MVPUT( ControlName + 'RootButton' , '.T.' )
		__MVPUBLIC ( ControlName + 'ItemIds' ) 
		__MVPUT( ControlName + 'ItemIds' , '.F.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 12
	///////////////////////////////////////////////////////////////////////
		DatePickerCount++
		ControlName := 'DatePicker_'+ALLTRIM(STR(DatePickerCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			DatePickerCount++
			ControlName := 'DatePicker_'+ALLTRIM(STR(DatePickerCount))
		EndDo

		@ _HMG_SYSDATA [ 191 ],_HMG_SYSDATA [ 192 ] DATEPICKER &ControlName OF &DesignForm FONT 'Arial' SIZE 9 TOOLTIP ControlName ON GOTFOCUS SelectControl(This.Name)

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , 'CTOD("  /  /  ")' )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'OnChange' ) 
		__MVPUT( ControlName + 'OnChange' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnGotFocus' ) 
		__MVPUT( ControlName + 'OnGotFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnLostFocus' ) 
		__MVPUT( ControlName + 'OnLostFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'OnEnter' ) 
		__MVPUT( ControlName + 'OnEnter' , 'Nil' )
		__MVPUBLIC ( ControlName + 'TabStop' ) 
		__MVPUT( ControlName + 'TabStop' , '.T.' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'ShowNone' ) 
		__MVPUT( ControlName + 'ShowNone' , '.F.' )
		__MVPUBLIC ( ControlName + 'UpDown' ) 
		__MVPUT( ControlName + 'UpDown' , '.F.' )
		__MVPUBLIC ( ControlName + 'RightAlign' ) 
		__MVPUT( ControlName + 'RightAlign' , '.F.' )
		__MVPUBLIC ( ControlName + 'Field' ) 
		__MVPUT( ControlName + 'Field' , 'Nil' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 13
	///////////////////////////////////////////////////////////////////////
		TextBoxCount++
		ControlName := 'Text_'+ALLTRIM(STR(TextBoxCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			TextBoxCount++
			ControlName := 'Text_'+ALLTRIM(STR(TextBoxCount))
		EndDo

		DEFINE TEXTBOX &ControlName
			PARENT &DesignForm
			ROW _HMG_SYSDATA [ 191 ]
			COL _HMG_SYSDATA [ 192 ]
			VALUE ControlName
			ON GOTFOCUS SelectControl( This.Name )
			FONTNAME 'ARIAL'
			FONTSIZE 9
		END TEXTBOX

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , "" )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'OnChange' ) 
		__MVPUT( ControlName + 'OnChange' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnGotFocus' ) 
		__MVPUT( ControlName + 'OnGotFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnLostFocus' ) 
		__MVPUT( ControlName + 'OnLostFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'InputMask' ) 
		__MVPUT( ControlName + 'InputMask' , '' )
		__MVPUBLIC ( ControlName + 'Format' ) 
		__MVPUT( ControlName + 'Format' , '' )
		__MVPUBLIC ( ControlName + 'DataType' ) 
		__MVPUT( ControlName + 'DataType' , 'CHARACTER' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'OnEnter' ) 
		__MVPUT( ControlName + 'OnEnter' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Field' ) 
		__MVPUT( ControlName + 'Field' , 'Nil' )
		__MVPUBLIC ( ControlName + 'BackColor' ) 
		__MVPUT( ControlName + 'BackColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontColor' ) 
		__MVPUT( ControlName + 'FontColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'TabStop' ) 
		__MVPUT( ControlName + 'TabStop' , '.T.' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'ReadOnly' ) 
		__MVPUT( ControlName + 'ReadOnly' , '.F.' )
		__MVPUBLIC ( ControlName + 'RightAlign' ) 
		__MVPUT( ControlName + 'RightAlign' , '.F.' )
		__MVPUBLIC ( ControlName + 'MaxLength' ) 
		__MVPUT( ControlName + 'MaxLength' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Password' ) 
		__MVPUT( ControlName + 'Password' , '.F.' )
		__MVPUBLIC ( ControlName + 'CaseConvert' ) 
		__MVPUT( ControlName + 'CaseConvert' , 'NONE' )

		__MVPUBLIC ( ControlName + 'DisabledBackColor' ) 
		__MVPUT( ControlName + 'DisabledBackColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'DisabledFontColor' ) 
		__MVPUT( ControlName + 'DisabledFontColor' , 'Nil' )


	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 14
	///////////////////////////////////////////////////////////////////////
		EditBoxCount++
		ControlName := 'Edit_'+ALLTRIM(STR(EditBoxCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			EditBoxCount++
			ControlName := 'Edit_'+ALLTRIM(STR(EditBoxCount))
		EndDo

		@ _HMG_SYSDATA [ 191 ],_HMG_SYSDATA [ 192 ] EDITBOX &ControlName OF &DesignForm WIDTH 120 HEIGHT 120 VALUE ControlName FONT 'ARIAL' SIZE 9 ON GOTFOCUS SelectControl (This.Name)

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , "" )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'OnChange' ) 
		__MVPUT( ControlName + 'OnChange' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnGotFocus' ) 
		__MVPUT( ControlName + 'OnGotFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnLostFocus' ) 
		__MVPUT( ControlName + 'OnLostFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'BackColor' ) 
		__MVPUT( ControlName + 'BackColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontColor' ) 
		__MVPUT( ControlName + 'FontColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'TabStop' ) 
		__MVPUT( ControlName + 'TabStop' , '.T.' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Field' ) 
		__MVPUT( ControlName + 'Field' , 'Nil' )
		__MVPUBLIC ( ControlName + 'MaxLength' ) 
		__MVPUT( ControlName + 'MaxLength' , 'Nil' )
		__MVPUBLIC ( ControlName + 'ReadOnly' ) 
		__MVPUT( ControlName + 'ReadOnly' , '.F.' )

		__MVPUBLIC ( ControlName + 'hScrollBar' ) 
		__MVPUT( ControlName + 'hScrollBar' , '.T.' )

		__MVPUBLIC ( ControlName + 'vScrollBar' ) 
		__MVPUT( ControlName + 'vScrollBar' , '.T.' )

		__MVPUBLIC ( ControlName + 'DisabledBackColor' ) 
		__MVPUT( ControlName + 'DisabledBackColor' , 'Nil' )

		__MVPUBLIC ( ControlName + 'DisabledFontColor' ) 
		__MVPUT( ControlName + 'DisabledFontColor' , 'Nil' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 15
	///////////////////////////////////////////////////////////////////////
		LabelCount++
		ControlName := 'Label_'+ALLTRIM(STR(LabelCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			LabelCount++
			ControlName := 'Label_'+ALLTRIM(STR(LabelCount))
		EndDo

		TabName := TabHit( _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] )

		if ( ! Empty ( TabName ) ) .AND. ( IsAppThemed() .Or. IsVista() )

			@ _HMG_SYSDATA [ 191 ],_HMG_SYSDATA [ 192 ] LABEL &ControlName OF &DesignForm VALUE ControlName FONT 'ARIAL' SIZE 9 ACTION SelectControl( This.Name ) TRANSPARENT

		else
		
			@ _HMG_SYSDATA [ 191 ],_HMG_SYSDATA [ 192 ] LABEL &ControlName OF &DesignForm VALUE ControlName FONT 'ARIAL' SIZE 9 ACTION SelectControl( This.Name )
	
		endif

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , ControlName )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'BackColor' ) 
		__MVPUT( ControlName + 'BackColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontColor' ) 
		__MVPUT( ControlName + 'FontColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Transparent' ) 
		__MVPUT( ControlName + 'Transparent' , '.F.' )
		__MVPUBLIC ( ControlName + 'Action' ) 
		__MVPUT( ControlName + 'Action' , 'Nil' )
		__MVPUBLIC ( ControlName + 'AutoSize' ) 
		__MVPUT( ControlName + 'AutoSize' , '.F.' )
		__MVPUBLIC ( ControlName + 'Alignment' ) 
		__MVPUT( ControlName + 'Alignment' , 'LEFT' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 16
	///////////////////////////////////////////////////////////////////////

		BrowseCount++
		ControlName := 'Browse_'+ALLTRIM(STR(BrowseCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			BrowseCount++
			ControlName := 'Browse_'+ALLTRIM(STR(BrowseCount))
		EndDo

		DEFINE BROWSE &ControlName
			PARENT &DesignForm
			ROW _HMG_SYSDATA [ 191 ]
			COL _HMG_SYSDATA [ 192 ]
			WIDTH 120
			HEIGHT 120
			HEADERS { ControlName } 
			WIDTHS { 100 } 
			WORKAREA Test 
			FIELDS { 'Test->Code' } 
			ON GOTFOCUS SelectControl (This.Name)
			VALUE 1
			FONTNAME 'ARIAL'
			FONTSIZE 9
			VSCROLLBAR .F.
		END BROWSE

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		DoMethod( DesignForm ,  ControlName , 'Refresh' )

		__MVPUBLIC ( ControlName + 'WorkArea' ) 
		__MVPUT( ControlName + 'WorkArea' , "Nil" )
		__MVPUBLIC ( ControlName + 'Fields' ) 
		__MVPUT( ControlName + 'Fields' , "{''}" )
		__MVPUBLIC ( ControlName + 'Headers' ) 
		__MVPUT( ControlName + 'Headers' , "{''}" )
		__MVPUBLIC ( ControlName + 'Widths' ) 
		__MVPUT( ControlName + 'Widths' , "{0}" )
		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , '0' )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'OnChange' ) 
		__MVPUT( ControlName + 'OnChange' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnGotFocus' ) 
		__MVPUT( ControlName + 'OnGotFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnLostFocus' ) 
		__MVPUT( ControlName + 'OnLostFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'BackColor' ) 
		__MVPUT( ControlName + 'BackColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontColor' ) 
		__MVPUT( ControlName + 'FontColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnDblClick' ) 
		__MVPUT( ControlName + 'OnDblClick' , 'Nil' )
		__MVPUBLIC ( ControlName + 'AllowEdit' ) 
		__MVPUT( ControlName + 'AllowEdit' , '.F.' )
		__MVPUBLIC ( ControlName + 'AllowAppend' ) 
		__MVPUT( ControlName + 'AllowAppend' , '.F.' )
		__MVPUBLIC ( ControlName + 'OnHeadClick' ) 
		__MVPUT( ControlName + 'OnHeadClick' , 'Nil' )
		__MVPUBLIC ( ControlName + 'AllowDelete' ) 
		__MVPUT( ControlName + 'AllowDelete' , '.F.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Image' ) 
		__MVPUT( ControlName + 'Image' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Justify' ) 
		__MVPUT( ControlName + 'Justify' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Lines' ) 
		__MVPUT( ControlName + 'Lines' , '.T.' )
		__MVPUBLIC ( ControlName + 'ReadOnlyFields' ) 
		__MVPUT( ControlName + 'ReadOnlyFields' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Valid' ) 
		__MVPUT( ControlName + 'Valid' , 'Nil' )
		__MVPUBLIC ( ControlName + 'ValidMessages' ) 
		__MVPUT( ControlName + 'ValidMessages' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Lock' ) 
		__MVPUT( ControlName + 'Lock' , '.F.' )
		__MVPUBLIC ( ControlName + 'vScrollBar' ) 
		__MVPUT( ControlName + 'vScrollBar' , '.T.' )

		__MVPUBLIC ( ControlName + 'DynamicBackColor' ) 
		__MVPUT( ControlName + 'DynamicBackColor' , 'Nil' )

		__MVPUBLIC ( ControlName + 'DynamicForeColor' ) 
		__MVPUT( ControlName + 'DynamicForeColor' , 'Nil' )

		__MVPUBLIC ( ControlName + 'InputMask' ) 
		__MVPUT( ControlName + 'InputMask' , 'Nil' )

		__MVPUBLIC ( ControlName + 'Format' ) 
		__MVPUT( ControlName + 'Format' , 'Nil' )

		__MVPUBLIC ( ControlName + 'When' ) 
		__MVPUT( ControlName + 'When' , 'Nil' )

		__MVPUBLIC ( ControlName + 'InputItems' ) 
		__MVPUT( ControlName + 'InputItems' , 'Nil' )

		__MVPUBLIC ( ControlName + 'DisplayItems' ) 
		__MVPUT( ControlName + 'DisplayItems' , 'Nil' )

		__MVPUBLIC ( ControlName + 'HeaderImages' ) 
		__MVPUT( ControlName + 'HeaderImages' , 'Nil' )


	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 17
	///////////////////////////////////////////////////////////////////////
		RadioGroupCount++
		ControlName := 'RadioGroup_'+ALLTRIM(STR(RadioGroupCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			RadioGroupCount++
			ControlName := 'RadioGroup_'+ALLTRIM(STR(RadioGroupCount))
		EndDo

		TabName := TabHit( _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] )

		if ! empty ( TabName )
			fmb := _HMG_SYSDATA [ 183 ]
			_HMG_SYSDATA [ 183 ] := 1
			_HMG_SYSDATA [ 225 ]  := TabName
			_HMG_SYSDATA [ 332 ] [_HMG_SYSDATA [ 183 ]] := DesignForm
		endif

		if ! empty ( TabName )
			_HMG_SYSDATA [ 266 ] := _HMG_SYSDATA [ 31 ] [ GetControlIndex ( TabName , DesignForm ) ]  
		endif

		DEFINE RADIOGROUP &ControlName
			PARENT &DesignForm
			ROW _HMG_SYSDATA [ 191 ]
			COL _HMG_SYSDATA [ 192 ]
			OPTIONS { 'Option 1','Option 2'}
			ON CHANGE SelectControl (This.Name)
			FONTNAME 'ARIAL'
			FONTSIZE 9
		END RADIOGROUP

		if ! empty ( TabName )
			_HMG_SYSDATA [ 183 ] := fmb
		endif

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		if ! empty ( TabName )
			_HMG_SYSDATA [ 16 ] [ GetControlIndex ( ControlName , DesignForm ) ] := _HMG_SYSDATA [ 31 ]  [ GetControlIndex ( TabName , DesignForm ) ] 
		endif

		__MVPUBLIC ( ControlName + 'Options' ) 
		__MVPUT( ControlName + 'Options' , "{ 'Option 1','Option 2'}" )
		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , '1' )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'OnChange' ) 
		__MVPUT( ControlName + 'OnChange' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'BackColor' ) 
		__MVPUT( ControlName + 'BackColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontColor' ) 
		__MVPUT( ControlName + 'FontColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'TabStop' ) 
		__MVPUT( ControlName + 'TabStop' , '.T.' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Transparent' ) 
		__MVPUT( ControlName + 'Transparent' , '.F.' )
		__MVPUBLIC ( ControlName + 'Spacing' ) 
		__MVPUT( ControlName + 'Spacing' , '25' )

		__MVPUBLIC ( ControlName + 'ReadOnly' ) 
		__MVPUT( ControlName + 'ReadOnly' , 'Nil' )

		__MVPUBLIC ( ControlName + 'Orientation' ) 
		__MVPUT( ControlName + 'Orientation' , 'VERTICAL' )


	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 18
	///////////////////////////////////////////////////////////////////////
		FrameCount++
		ControlName := 'Frame_'+ALLTRIM(STR(FrameCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			FrameCount++
			ControlName := 'Frame_'+ALLTRIM(STR(FrameCount))
		EndDo

		TabName := TabHit( _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] )

		if ! empty ( TabName )
			fmb := _HMG_SYSDATA [ 183 ]
			_HMG_SYSDATA [ 183 ] := 1
			_HMG_SYSDATA [ 225 ]  := TabName
			_HMG_SYSDATA [ 332 ] [_HMG_SYSDATA [ 183 ]] := DesignForm
		endif

		if ! empty ( TabName )
			_HMG_SYSDATA [ 266 ] := _HMG_SYSDATA [ 31 ] [ GetControlIndex ( TabName , DesignForm ) ]  
		endif

		DEFINE FRAME &ControlName
			PARENT &DesignForm
			ROW _HMG_SYSDATA [ 191 ]
			COL _HMG_SYSDATA [ 192 ]
			CAPTION ControlName
			FONTNAME 'ARIAL'
			FONTSIZE 9
			OPAQUE .T.
		END FRAME

		if ! empty ( TabName )
			_HMG_SYSDATA [ 183 ] := fmb
		endif

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		if ! empty ( TabName )
			_HMG_SYSDATA [ 16 ] [ GetControlIndex ( ControlName , DesignForm ) ] := _HMG_SYSDATA [ 31 ]  [ GetControlIndex ( TabName , DesignForm ) ] 
		endif

		__MVPUBLIC ( ControlName + 'Caption' ) 
		__MVPUT( ControlName + 'Caption' , ControlName )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'Transparent' ) 
		__MVPUT( ControlName + 'Transparent' , '.F.' )
		__MVPUBLIC ( ControlName + 'BackColor' ) 
		__MVPUT( ControlName + 'BackColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontColor' ) 
		__MVPUT( ControlName + 'FontColor' , 'Nil' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 19
	///////////////////////////////////////////////////////////////////////

		if Empty ( TabHit( _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] ) )

			TabCount++
			ControlName := 'Tab_'+ALLTRIM(STR(TabCount))

			Do While _IsControlDefined (ControlName,DesignForm)
				TabCount++
				ControlName := 'Tab_'+ALLTRIM(STR(TabCount))
			EndDo

			DEFINE TAB &ControlName	OF &DesignForm AT _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] WIDTH 150 HEIGHT 120 ON CHANGE ( SelectControl ( This.Name ) , SelectControl ( This.Name ) )
				PAGE 'Page 1'
				END PAGE
				PAGE 'Page 2'
				END PAGE
			END TAB

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

			__MVPUBLIC ( ControlName + 'PageCount' ) 
			__MVPUT( ControlName + 'PageCount' , '2' )
			__MVPUBLIC ( ControlName + 'Captions' ) 
			__MVPUT( ControlName + 'Captions' , "{ 'Page 1' , 'Page 2' }" )

			__MVPUBLIC ( ControlName + 'PageImages' ) 
			__MVPUT( ControlName + 'PageImages' , "{'',''}" )

			__MVPUBLIC ( ControlName + 'Value' ) 
			__MVPUT( ControlName + 'Value' , '1' )
			__MVPUBLIC ( ControlName + 'FontName' ) 
			__MVPUT( ControlName + 'FontName' , 'Arial' )
			__MVPUBLIC ( ControlName + 'FontSize' ) 
			__MVPUT( ControlName + 'FontSize' , '9' )
			__MVPUBLIC ( ControlName + 'ToolTip' ) 
			__MVPUT( ControlName + 'ToolTip' , '' )
			__MVPUBLIC( ControlName + 'OnChange' )
			__MVPUT( ControlName + 'OnChange' , 'Nil' )
			__MVPUBLIC ( ControlName + 'FontBold' ) 
			__MVPUT( ControlName + 'FontBold' , '.F.' )
			__MVPUBLIC ( ControlName + 'FontItalic' ) 
			__MVPUT( ControlName + 'FontItalic' , '.F.' )
			__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
			__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
			__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( ControlName + 'Buttons' ) 
			__MVPUT( ControlName + 'Buttons' , '.F.' )
			__MVPUBLIC ( ControlName + 'Flat' ) 
			__MVPUT( ControlName + 'Flat' , '.F.' )
			__MVPUBLIC ( ControlName + 'HotTrack' ) 
			__MVPUT( ControlName + 'HotTrack' , '.F.' )
			__MVPUBLIC ( ControlName + 'Vertical' ) 
			__MVPUT( ControlName + 'Vertical' , '.F.' )
			__MVPUBLIC ( ControlName + 'TabStop' ) 
			__MVPUT( ControlName + 'TabStop' , '.T.' )

			__MVPUBLIC ( ControlName + 'MultiLine' ) 
			__MVPUT( ControlName + 'MultiLine' , '.F.' )


		EndIf

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 20
	///////////////////////////////////////////////////////////////////////
		AnimateCount++
		ControlName := 'Animate_'+ALLTRIM(STR(AnimateCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			AnimateCount++
			ControlName := 'Animate_'+ALLTRIM(STR(AnimateCount))
		EndDo

		DEFINE ANIMATEBOX &ControlName
			PARENT &DesignForm
			ROW _HMG_SYSDATA [ 191 ]
			COL _HMG_SYSDATA [ 192 ]
			WIDTH 210
			HEIGHT 60 
			FILE ''
			CENTER .T.
			AUTOPLAY .T.
		END ANIMATEBOX

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		DoMethod ( DesignForm , ControlName , 'Play' )

		__MVPUBLIC ( ControlName + 'File' ) 
		__MVPUT( ControlName + 'File' , '' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Transparent' ) 
		__MVPUT( ControlName + 'Transparent' , '.F.' )
		__MVPUBLIC ( ControlName + 'AutoPlay' ) 
		__MVPUT( ControlName + 'AutoPlay' , '.F.' )
		__MVPUBLIC ( ControlName + 'Center' ) 
		__MVPUT( ControlName + 'Center' , '.F.' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 21
	///////////////////////////////////////////////////////////////////////
		HyperLinkCount++
		ControlName := 'HyperLink_'+ALLTRIM(STR(HyperLinkCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			HyperLinkCount++
			ControlName := 'HyperLink_'+ALLTRIM(STR(HyperLinkCount))
		EndDo


		TabName := TabHit( _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] )

		if ( ! Empty ( TabName ) ) .AND. IsAppThemed()

		DEFINE HyperLink &ControlName
			PARENT &DesignForm
			ROW _HMG_SYSDATA [ 191 ]
			COL _HMG_SYSDATA [ 192 ]
			WIDTH 230
			HEIGHT 28
			VALUE _HLK
			ADDRESS _HLK
			FONTNAME 'ARIAL'
			FONTSIZE 9
			TRANSPARENT .T.
		END HYPERLINK

		else

		DEFINE HyperLink &ControlName
			PARENT &DesignForm
			ROW _HMG_SYSDATA [ 191 ]
			COL _HMG_SYSDATA [ 192 ]
			WIDTH 230
			HEIGHT 28
			VALUE _HLK
			ADDRESS _HLK
			FONTNAME 'ARIAL'
			FONTSIZE 9
		END HYPERLINK

		endif

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		i := GetControlIndex ( ControlName , DesignForm )

		_HMG_SYSDATA [ 39 ] [ i ] := 6

		macrovar := 'SelectControl ('+ chr(34) + 'HyperLink_' + ALLTRIM(STR(HyperLinkCount)) + chr(34) + ')'

		_HMG_SYSDATA [ 6 ] [i] := { || &macrovar } 

		RedrawWindow ( GetControlHandle ( ControlName , DesignForm ) )

		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , _HLK )
		__MVPUBLIC ( ControlName + 'Address' ) 
		__MVPUT( ControlName + 'Address' , _HLK )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'AutoSize' ) 
		__MVPUT( ControlName + 'AutoSize' , '.F.' )
		__MVPUBLIC ( ControlName + 'BackColor' ) 
		__MVPUT( ControlName + 'BackColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontColor' ) 
		__MVPUT( ControlName + 'FontColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'HandCursor' ) 
		__MVPUT( ControlName + 'HandCursor' , '.F.' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 22
	///////////////////////////////////////////////////////////////////////
		MonthCalendarCount++
		ControlName := 'MonthCal_'+ALLTRIM(STR(MonthCalendarCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			MonthCalendarCount++
			ControlName := 'MonthCal_'+ALLTRIM(STR(MonthCalendarCount))
		EndDo

		@ _HMG_SYSDATA [ 191 ],_HMG_SYSDATA [ 192 ] MONTHCALENDAR &ControlName OF &DesignForm ;
		VALUE date() ;
		FONT 'ARIAL' SIZE 9 ;
		ON CHANGE SelectControl (This.Name)

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , 'CTOD("  /  /  ")' )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'OnChange' ) 
		__MVPUT( ControlName + 'OnChange' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'Today' ) 
		__MVPUT( ControlName + 'Today' , '.T.' )
		__MVPUBLIC ( ControlName + 'TodayCircle' ) 
		__MVPUT( ControlName + 'TodayCircle' , '.T.' )
		__MVPUBLIC ( ControlName + 'WeekNumbers' ) 
		__MVPUT( ControlName + 'WeekNumbers' , '.F.' )
		__MVPUBLIC ( ControlName + 'TabStop' ) 
		__MVPUT( ControlName + 'TabStop' , '.T.' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 23
	///////////////////////////////////////////////////////////////////////
		RichEditCount++
		ControlName := 'RichEdit_'+ALLTRIM(STR(RichEditCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			RichEditCount++
			ControlName := 'RichEdit_'+ALLTRIM(STR(RichEditCount))
		EndDo

		DEFINE RICHEDITBOX &ControlName
			PARENT &DesignForm
			ROW _HMG_SYSDATA [ 191 ]
			COL _HMG_SYSDATA [ 192 ]
			WIDTH 120
			HEIGHT 120
			ON GOTFOCUS SelectControl (This.Name)
			VALUE ControlName
			FONTNAME 'ARIAL'
			FONTSIZE 9
		END RICHEDITBOX

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , '' )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'OnChange' ) 
		__MVPUT( ControlName + 'OnChange' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnGotFocus' ) 
		__MVPUT( ControlName + 'OnGotFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnLostFocus' ) 
		__MVPUT( ControlName + 'OnLostFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'TabStop' ) 
		__MVPUT( ControlName + 'TabStop' , '.T.' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'BackColor' ) 
		__MVPUT( ControlName + 'BackColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'MaxLength' ) 
		__MVPUT( ControlName + 'MaxLength' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Field' ) 
		__MVPUT( ControlName + 'Field' , 'Nil' )
		__MVPUBLIC ( ControlName + 'ReadOnly' ) 
		__MVPUT( ControlName + 'ReadOnly' , '.F.' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 24
	///////////////////////////////////////////////////////////////////////
		ProgressBarCount++
		ControlName := 'ProgressBar_'+ALLTRIM(STR(ProgressBarCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			ProgressBarCount++
			ControlName := 'ProgressBar_'+ALLTRIM(STR(ProgressBarCount))
		EndDo

		@ _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] LABEL &ControlName ;
			OF &DesignForm ;
			VALUE ControlName ACTION SelectControl (This.Name) ;
			WIDTH 150 HEIGHT 30 ;
			BORDER

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		_HMG_SYSDATA [ 39 ] [ GetControlIndex ( ControlName , DesignForm ) ] := 2

		__MVPUBLIC ( ControlName + 'RangeMin' ) 
		__MVPUT( ControlName + 'RangeMin' , '1' )
		__MVPUBLIC ( ControlName + 'RangeMax' ) 
		__MVPUT( ControlName + 'RangeMax' , '10' )
		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , '0' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'BackColor' ) 
		__MVPUT( ControlName + 'BackColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'ForeColor' ) 
		__MVPUT( ControlName + 'ForeColor' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )
		__MVPUBLIC ( ControlName + 'Smooth' ) 
		__MVPUT( ControlName + 'Smooth' , '.F.' )
		__MVPUBLIC ( ControlName + 'Orientation' ) 
		__MVPUT( ControlName + 'Orientation' , 'HORIZONTAL' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 25
	///////////////////////////////////////////////////////////////////////
		PlayerCount++
		ControlName := 'Player_'+ALLTRIM(STR(PlayerCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			PlayerCount++
			ControlName := 'Player_'+ALLTRIM(STR(PlayerCount))
		EndDo

		@ _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] LABEL &ControlName ;
			OF &DesignForm ;
			VALUE ControlName ACTION SelectControl (This.Name) ;
			WIDTH 120 HEIGHT 120 ;
			BORDER

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		_HMG_SYSDATA [ 39 ] [ GetControlIndex ( ControlName , DesignForm ) ] := 3

		__MVPUBLIC ( ControlName + 'File' ) 
		__MVPUT( ControlName + 'File' , '' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )


		__MVPUBLIC ( ControlName + 'AutoSizeWindow' ) 
		__MVPUT( ControlName + 'AutoSizeWindow' , '.T.' )

		__MVPUBLIC ( ControlName + 'AutoSizeMovie' ) 
		__MVPUT( ControlName + 'AutoSizeMovie' , '.T.' )

		__MVPUBLIC ( ControlName + 'ErrorDlg' ) 
		__MVPUT( ControlName + 'ErrorDlg' , '.T.' )

		__MVPUBLIC ( ControlName + 'Menu' ) 
		__MVPUT( ControlName + 'Menu' , '.T.' )

		__MVPUBLIC ( ControlName + 'Open' ) 
		__MVPUT( ControlName + 'Open' , '.T.' )

		__MVPUBLIC ( ControlName + 'PlayBar' ) 
		__MVPUT( ControlName + 'PlayBar' , '.T.' )

		__MVPUBLIC ( ControlName + 'ShowAll' ) 
		__MVPUT( ControlName + 'ShowAll' , '.F.' )

		__MVPUBLIC ( ControlName + 'ShowMode' ) 
		__MVPUT( ControlName + 'ShowMode' , '.F.' )

		__MVPUBLIC ( ControlName + 'ShowName' ) 
		__MVPUT( ControlName + 'ShowName' , '.F.' )

		__MVPUBLIC ( ControlName + 'ShowPosition' ) 
		__MVPUT( ControlName + 'ShowPosition' , '.F.' )





	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 26
	///////////////////////////////////////////////////////////////////////
		IpAddressCount++
		ControlName := 'IpAddress_'+ALLTRIM(STR(IpAddressCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			IpAddressCount++
			ControlName := 'IpAddress_'+ALLTRIM(STR(IpAddressCount))
		EndDo

		@ _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] LABEL &ControlName ;
			OF &DesignForm ;
			VALUE ControlName ACTION SelectControl (This.Name) ;
			FONT 'ARIAL' SIZE 9 ;
			BORDER

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		_HMG_SYSDATA [ 39 ] [ GetControlIndex ( ControlName , DesignForm ) ] := 4

		__MVPUBLIC ( ControlName + 'Value' ) 
		__MVPUT( ControlName + 'Value' , '{ 0 , 0 , 0 , 0 }' )
		__MVPUBLIC ( ControlName + 'FontName' ) 
		__MVPUT( ControlName + 'FontName' , 'Arial' )
		__MVPUBLIC ( ControlName + 'FontSize' ) 
		__MVPUT( ControlName + 'FontSize' , '9' )
		__MVPUBLIC ( ControlName + 'ToolTip' ) 
		__MVPUT( ControlName + 'ToolTip' , '' )
		__MVPUBLIC ( ControlName + 'OnChange' ) 
		__MVPUT( ControlName + 'OnChange' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnGotFocus' ) 
		__MVPUT( ControlName + 'OnGotFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'OnLostFocus' ) 
		__MVPUT( ControlName + 'OnLostFocus' , 'Nil' )
		__MVPUBLIC ( ControlName + 'FontBold' ) 
		__MVPUT( ControlName + 'FontBold' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontItalic' ) 
		__MVPUT( ControlName + 'FontItalic' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontStrikeOut' ) 
		__MVPUT( ControlName + 'FontStrikeOut' , '.F.' )
		__MVPUBLIC ( ControlName + 'FontUnderLine' ) 
		__MVPUT( ControlName + 'FontUnderLine' , '.F.' )
		__MVPUBLIC ( ControlName + 'TabStop' ) 
		__MVPUT( ControlName + 'TabStop' , '.T.' )
		__MVPUBLIC ( ControlName + 'Visible' ) 
		__MVPUT( ControlName + 'Visible' , '.T.' )
		__MVPUBLIC ( ControlName + 'HelpId' ) 
		__MVPUT( ControlName + 'HelpId' , 'Nil' )

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 27
	///////////////////////////////////////////////////////////////////////

		if Empty ( TabHit( _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] ) )

			TimerCount++
			ControlName := 'Timer_'+ALLTRIM(STR(TimerCount))

			Do While _IsControlDefined (ControlName,DesignForm)
				TimerCount++
				ControlName := 'Timer_'+ALLTRIM(STR(TimerCount))
			EndDo

			DEFINE BUTTON &ControlName
				PARENT &DesignForm
				ROW _HMG_SYSDATA [ 191 ]
				COL _HMG_SYSDATA [ 192 ]
				WIDTH 30 
				HEIGHT 30 
				ACTION SelectControl (This.name)
				PICTURE 'timer'
				FLAT .T.
			END BUTTON

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

			_HMG_SYSDATA [ 39 ] [ GetControlIndex ( ControlName , DesignForm ) ] := 5

			__MVPUBLIC ( ControlName + 'Interval' ) 
			__MVPUT( ControlName + 'Interval' , '0' )
			__MVPUBLIC ( ControlName + 'Action' ) 
			__MVPUT( ControlName + 'Action' , 'Nil' )
			
		endif

		/*
			1: CHECKBUTTON
			2: PROGRESSBAR
			3: PLAYER
			4: IPADDRESS
			5: TIMER
			6: HYPERLINK
			7: ACTIVEX
			8: CHILD WINDOW
		*/

	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 35
	///////////////////////////////////////////////////////////////////////
		ActivexCount++
		ControlName := 'Activex_'+ALLTRIM(STR(ActivexCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			ActivexCount++
			ControlName := 'Activex_'+ALLTRIM(STR(ActivexCount))
		EndDo

		@ _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] LABEL &ControlName ;
			OF &DesignForm ;
			VALUE ControlName ACTION SelectControl (This.Name) ;
			WIDTH 150 HEIGHT 150 ;
			FONT 'ARIAL' SIZE 9 ;
			BORDER

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		_HMG_SYSDATA [ 39 ] [ GetControlIndex ( ControlName , DesignForm ) ] := 7

		__MVPUBLIC ( ControlName + 'ProgId' ) 
		__MVPUT( ControlName + 'ProgId' , '' )


	///////////////////////////////////////////////////////////////////////
	Case CurrentControl == 36
	///////////////////////////////////////////////////////////////////////
		ChildWindowCount++
		ControlName := 'PanelWindow_'+ALLTRIM(STR(ChildWindowCount))

		Do While _IsControlDefined (ControlName,DesignForm)
			ChildWindowCount++
			ControlName := 'PanelWindow_'+ALLTRIM(STR(ChildWindowCount))
		EndDo

		@ _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] LABEL &ControlName ;
			OF &DesignForm ;
			VALUE ControlName ACTION SelectControl (This.Name) ;
			WIDTH 150 HEIGHT 150 ;
			FONT 'ARIAL' SIZE 9 ;
			BORDER

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif

		_HMG_SYSDATA [ 39 ] [ GetControlIndex ( ControlName , DesignForm ) ] := 8

	EndCase

	TabName := ''

	If (CurrentControl >= 2 .and. CurrentControl <= 27) .Or. CurrentControl == 35 .Or. CurrentControl == 36  .Or. CurrentControl == 99

		If CurrentControl != 19 .and. CurrentControl != 27

			TabName := TabHit( _HMG_SYSDATA [ 191 ] , _HMG_SYSDATA [ 192 ] )

			if ! empty ( TabName )

				SelectControl ( TabName )

				TabIndex := GetControlIndex ( TabName , DesignForm )

				TabRow	:= GetProperty ( DesignForm , TabName , 'Row' )
				TabCol	:= GetProperty ( DesignForm , TabName , 'Col' )
				TabWidth := GetProperty ( DesignForm , TabName , 'Width' )
				TabHeight := GetProperty ( DesignForm , TabName , 'Height' )
				TabCaptions := _HMG_SYSDATA [ 33 ]   [TabIndex]
				TabPage := GetProperty ( DesignForm , TabName , 'Value' )

				if __MVGET ( Tabname + 'buttons' ) == '.T.'
					TMPBUTTONS := .T.
				else
					TMPBUTTONS := .F.
				endif

				if __MVGET ( Tabname + 'flat' ) == '.T.'
					tabflat := .T.
				else
					tabflat := .F.
				endif

				DoMethod ( DesignForm , TabName , 'AddControl' , ControlName , TabPage , _HMG_SYSDATA [ 191 ] - TabRow , _HMG_SYSDATA [ 192 ] - TabCol )

				if CurrentControl == 2
					_HMG_SYSDATA [31] [ GetControlIndex ( ControlName , DesignForm ) ] := TabName
				endif
				if CurrentControl == 7
					_HMG_SYSDATA [31] [ GetControlIndex ( ControlName , DesignForm ) ] := TabName
				endif
				if CurrentControl == 12
					_HMG_SYSDATA [31] [ GetControlIndex ( ControlName , DesignForm ) ] := TabName
				endif
				if CurrentControl == 13
					_HMG_SYSDATA [31] [ GetControlIndex ( ControlName , DesignForm ) ] := TabName
				endif
				if CurrentControl == 14
					_HMG_SYSDATA [31] [ GetControlIndex ( ControlName , DesignForm ) ] := TabName
				endif
				if CurrentControl == 15
					_HMG_SYSDATA [31] [ GetControlIndex ( ControlName , DesignForm ) ] := TabName
				endif
				if CurrentControl == 16
					_HMG_SYSDATA [37] [ GetControlIndex ( ControlName , DesignForm ) ] := TabName
				endif
				if CurrentControl == 22
					_HMG_SYSDATA [31] [ GetControlIndex ( ControlName , DesignForm ) ] := TabName
				endif

				if CurrentControl == 18
					releaseControl (_HMG_SYSDATA [   3 ] [tabindex] )
					_HMG_SYSDATA [   3 ] [tabindex] := InitTabControl ( DesignFormhandle, 0, tabcol, tabrow, tabwidth, tabheight , tabcaptions, tabpage, '', 0 , TMPBUTTONS , TabFlat , .f. , .f. , .f. )
					DeleteObject ( _HMG_SYSDATA [ 36 ] [tabindex] ) 
					_HMG_SYSDATA [ 36 ] [tabindex] := _SetFont ( _HMG_SYSDATA [   3 ] [tabindex] , 'Arial' , 9 , .f. , .f. , .f. , .f. )
					DrawGrid()
					SelectControl (ControlName)
					Redrawwindow( GetControlhandle ( ControlName , DesignForm ) )
				else

					* MiniGUI Bug!!!!
					SetProperty ( DesignForm , TabName , 'Row' , TabRow )
					DrawGrid()
					SelectControl (ControlName)
					if CurrentControl != 9 .and. CurrentControl != 16 .and. CurrentControl != 17
						Redrawwindow( GetControlhandle ( ControlName , DesignForm ) )
					endif

				endif

			Else

				SelectControl ( Controlname )

			EndIf

		Else

			SelectControl ( Controlname )

		EndIf

		if lVirtualForm
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEDOWN , 0 )
			SendMessage ( GetFormhandle ( DesignForm ) , WM_VSCROLL , SB_LINEUP , 0 )
		endif


	EndIf

	if CurrentControl == 19 
		SelectControl ( Controlname )
	EndIf

	///////////////////////////////////////////////////////////////////////
	// Reset Control Selection
	///////////////////////////////////////////////////////////////////////

	ResetToolBar()

	SendMessage( GetControlHandle('Control_01','Form_Main') , BM_SETCHECK  , BST_CHECKED , 0 )
	CurrentControl := 1

RETURN