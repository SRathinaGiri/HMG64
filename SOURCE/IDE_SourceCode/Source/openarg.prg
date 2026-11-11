*------------------------------------------------------------------------------*
PROCEDURE _Open( Arg )
*------------------------------------------------------------------------------*
LOCAL Line, NextToken, cUserPropertyName, cUserPropertyValue 
LOCAL CurrentRowSource, CurrentColumnFields, CurrentAllowDelete, CurrentBuffered, CurrentDynamicDisplay, CurrentWhen
LOCAL CurrentDynamicBackColor, CurrentDynamicForeColor, CurrentColumnWhen, CurrentColumnValid, CurrentColumnControls
LOCAL CurrentUpperCase, CurrentLowerCase, CurrentVertical, CurrentPictAlignment, CurrentCenterAlign, CurrentTransparent
LOCAL CurrentOnGotFocus, CurrentOnLostFocus, WinRow, WinCol, VirtualWidth, VirtualHeight
Local LineBuffer , Width , Height , char , Row , Col , Started , c , z , a , ControlType, x , FileName , Code , LineCount , i , w , b
Local CurrentRow
Local CurrentCol
Local CurrentWidth
Local CurrentHeight
Local CurrentCaption
Local CurrentAction
Local TimersLoaded := 0
Local TabPageCount := 0
Local CurrentItems
Local CurrentRangeMax
Local CurrentRangeMin
Local CurrentPicture
Local CurrentValue
Local CurrentWorkArea
Local CurrentFields
Local CurrentHeaders
Local CurrentWidths
Local CurrentOptions
Local CurrentCaptions
Local CurrentFile
Local CurrentAddress
Local Interval
Local aTemp
Local Value
Local Title
Local WindowType
Local CurrentFontName := 'Arial'
Local CurrentFontSize := 9
Local Fontname
Local FontSize
Local CurrentToolTip
Local CurrentOnChange
Local ToolTip
Local OnChange
Local OnGotFocus
Local OnLostFocus
Local CurrentInputmask
Local CurrentFormat
Local CurrentNumeric
Local CurrentDate
Local QuoteFlag
Local CurrentFontBold
Local CurrentFontItalic
Local CurrentFontUnderLine
Local CurrentFontStrikeout
Local CurrentHelpId
Local CurrentFlat
Local CurrentTabStop
Local CurrentVisible
Local CurrentField
Local CurrentBackColor
Local CurrentFontColor
Local CurrentOnDblClick
Local CurrentOnSave
Local CurrentSort
Local CurrentMultiSelect
Local CurrentOnEnter
Local CurrentOnDisplayChange
Local CurrentDisplayEdit
Local CurrentItemSource
Local CurrentValueSource
Local CurrentOnHeadClick
Local CurrentOnQueryData
Local CurrentAllowEdit
Local CurrentVirtual
Local CurrentLines
Local CurrentImage
Local CurrentJustify
Local CurrentItemCount
Local CurrentBoth
Local CurrentTop
Local CurrentLeft
Local CurrentNoTicks
Local CurrentWrap
Local CurrentReadOnly
Local CurrentIncrement
Local CurrentStretch
Local CurrentUpDown
Local CurrentShowNone
Local CurrentRightAlign
Local CurrentMaxLength
Local CurrentPassword
Local CurrentAutoSize
Local OnDblClick
Local NodeImages
Local ItemImages
Local HelpId
Local CurrentAllowAppend
Local CurrentreadOnlyFields
Local CurrentValid
Local CurrentValidMessages
Local CurrentLock
Local CurrentvScrollBar
Local CurrentSpacing
Local CurrentOpaque
Local CurrentMediaProp
Local CurrentSmooth
Local CurrentToday
Local CurrentTodayCircle
Local CurrentMultiLine
Local CurrentWeekNumbers
Local CurrentHandCursor
Local CurrentAutoPlay
Local CurrentCenter
Local ClauseArgument
Local Icon
Local CurrentMenuLevel := 0
Local _hmgide_MainMenuProcessing := .F.
Local _hmgide_ContextMenuProcessing := .F.
Local _hmgide_StatusBarProcessing := .F.
Local _hmgide_ToolBarProcessing := .F.
Local _hmgide_NotifyMenuProcessing := .F.
Local _hmgide_DropDownMenuProcessing := .F.
Local _hmgide_SplitBoxProcessing := .F.
Local CurrentPageImages
Local CurrentTabName
local _hmgide_CurrentDropDownMenu := ''
local CURRENTHSCROLLBAR 
Local CurrentShowHeaders
Local cTmpName
local CurrentHorizontal
Local CurrentProgId

Local CurrentInputItems
Local CurrentDisplayItems

Local CurrentDroppedWidth
Local CurrentOnDropDown
Local CurrentOnCloseUp

Local CurrentHeaderImages
Local t
Local lUserControlActive := .F.
Local cUserControlName := ''
Local cCurrentComponentType := ''
Local nCurrentComponentSubType := 0
Local CurrentDragItems
Local CurrentCellNavigation := .F.

Local CurrentDisabledBackColor
Local CurrentDisabledFontColor

Local xWidth
Local xHeight

Local CurrentLockColumns

Private Name
Private MacroVar

_hmgide_CurrentMainMenu := ''
_hmgide_CurrentContextMenu := ''
_hmgide_CurrentNotifyMenu := ''
_hmgide_CurrentStatusBar := ''
_hmgide_CurrentToolBar := ''
_hmgide_CurrentToolBar := ''
_hmgide_aDropDownMenus := {}
_hmgide_CurrentSplitBox := ''

*	1: CHECKBUTTON
*	2: PROGRESSBAR
*	3: PLAYER
*	4: IPADDRESS
*	5: TIMER
*	6: HYPERLINK
*	7: ACTIVEX

	InitControlCounters()

	*msginfo(arg)

	CurrentControl := 1
	SelectedControlName := ''
	SelectedControlIndex := 0

	If VALTYPE ( Arg ) == 'C'
		FileName := Arg
	Else
		FileName := Getfile ( { {'HMG Forms','*.fmg'} } , 'Open File' , , .f. , .f. )
	EndIf

	If Empty (FileName)
		RETURN
	Endif

	Code := HB_MEMOREAD ( FileName )

	LineCount := MlCount (Code)

	LineBuffer := ''

	loading.progress_1.rangemax := LineCount
	loading.show

	For i := 1 To LineCount

		Line := ALLTRIM ( MemoLine ( Code , 1024 , i , 4 , .t. ) )

		loading.progress_1.value := i

		* Join Splitted Lines

		if HB_URIGHT ( Line , 1 ) == ';'

			Line := HB_ULEFT ( Line , HMG_LEN ( Line ) - 1 ) + ' ' 

			LineBuffer := LineBuffer + Line
			Loop

		Else

			if ! Empty ( LineBuffer ) 

				Line := LineBuffer + Line
				LineBuffer := ''

			EndIf
				
		Endif

		*

		Line := RemoveExtraSpaces (Line)



		// PROCESS USER COMPONENTS


		If lUserControlActive == .F.

			For t := 1 To HMG_LEN (aComponentNames)
				
				If HMG_UPPER( Line ) = 'DEFINE ' + ALLTRIM(HMG_UPPER(aComponentNames[t])) + ' ' 
                		
					cUserControlName := ALLTRIM ( HB_USUBSTR ( Line , HB_UTF8RAT ( ' ' , Line ) , 128 ) )

					cCurrentComponentType := ALLTRIM(HMG_UPPER(aComponentNames[t]))

					nCurrentComponentSubType := t

					lUserControlActive := .T.

					Exit

				EndIf

			Next t

			If lUserControlActive == .T.

				Loop

			EndIf

		Else

			If HMG_UPPER (Line) = 'ROW'
				CurrentRow := VAL ( HB_USUBSTR ( Line , 5 , HMG_LEN (Line) - 4 ) )

			ElseIf HMG_UPPER (Line) = 'COL'
				CurrentCol := VAL ( HB_USUBSTR ( Line , 5 , HMG_LEN (Line) - 4 ) )

			ElseIf HMG_UPPER ( HB_ULEFT ( Line , 6 ) ) == 'WIDTH ' 
				CurrentWidth := VAL ( HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

			ElseIf HMG_UPPER (Line) = 'HEIGHT'
				CurrentHeight := VAL ( HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )

			ElseIf HMG_UPPER( Line ) = 'END ' + ALLTRIM(HMG_UPPER(cCurrentComponentType))

				@ CurrentRow , CurrentCol LABEL &cUserControlName ;
					OF &DesignForm ;
					VALUE cUserControlName ACTION SelectControl (This.Name) ;
					WIDTH CurrentWidth HEIGHT CurrentHeight ;
					FONT 'ARIAL' SIZE 9 ;
					BORDER

				_HMG_SYSDATA [ 39 ] [ GetControlIndex ( cUserControlName , DesignForm ) ] := 10 + nCurrentComponentSubType 

				lUserControlActive		:= .F.
				cCurrentComponentType		:= ''
				cUserControlName		:= ''
				nCurrentComponentSubType	:= 0

				Loop

			Else

				cUserPropertyName := ALLTRIM ( HB_ULEFT ( Line , HB_UAT ( ' ' , Line ) ) )				
				cUserPropertyValue := ALLTRIM ( HB_USUBSTR ( Line , HB_UTF8RAT ( ' ' , Line ) , 128 ) )
		
				__MVPUBLIC ( cUserControlName + cUserPropertyName )

				__MVPUT ( cUserControlName + cUserPropertyName , cUserPropertyValue )

			EndIf

		EndIf

		//


		// DEFINE COMMAND

		If	HMG_UPPER (Line) = 'DEFINE MAIN MENU' 

			_hmgide_CurrentMainMenu := _hmgide_CurrentMainMenu + Space(4) + Line + CRLF
			CurrentMenuLevel := 1

			_hmgide_MainMenuProcessing	:= .T.
			_hmgide_ContextMenuProcessing	:= .F.
			_hmgide_NotifyMenuProcessing	:= .F.
			_hmgide_DropDownMenuProcessing	:= .F.

		ElseIf	HMG_UPPER (Line) = 'DEFINE TOOLBAR' 

			if _hmgide_SplitBoxProcessing == .T.
				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(8) + Line + CRLF

				cTmpName := ALLTRIM ( HB_USUBSTR ( Line , 16 , 255 ) )
				cTmpName := ALLTRIM ( HB_ULEFT ( cTmpName , HB_UAT( ' ' , cTmpName ) ) )

				__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( cTmpName ) ) + 'SpxToolBar' ) 
				__MVPUT ( HMG_UPPER ( ALLTRIM ( cTmpName ) ) + 'SpxToolBar' , Space (8) + Line + CRLF ) 

			else
				_hmgide_CurrentToolBar := _hmgide_CurrentToolBar + Space(4) + Line + CRLF
			endif

			_hmgide_ToolBarProcessing := .T.

		ElseIf	HMG_UPPER (Line) = 'BUTTON ' 

			if _hmgide_ToolBarProcessing == .T.

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + Line + CRLF
					__MVPUT ( HMG_UPPER ( ALLTRIM ( cTmpName ) ) + 'SpxToolBar' , __MVGET ( HMG_UPPER ( ALLTRIM ( cTmpName ) ) + 'SpxToolBar' ) + Space (12) + Line + CRLF ) 
				else
					_hmgide_CurrentToolBar := _hmgide_CurrentToolBar + Space(8) + Line + CRLF
				EndIf

			EndIf

		ElseIf	HMG_UPPER (Line) = 'END TOOLBAR'

			if _hmgide_ToolBarProcessing == .T.
				_hmgide_ToolBarProcessing := .F.

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(8) + Line + CRLF
					__MVPUT ( HMG_UPPER ( ALLTRIM ( cTmpName ) ) + 'SpxToolBar' , __MVGET ( HMG_UPPER ( ALLTRIM ( cTmpName ) ) + 'SpxToolBar' ) + Space (8) + Line + CRLF ) 
				else
					_hmgide_CurrentToolBar := _hmgide_CurrentToolBar + Space(4) + Line + CRLF
				endif

				CurrentMenuLevel := 0
			endif

		ElseIf	HMG_UPPER (Line) = 'DEFINE CONTEXT MENU' 

			_hmgide_CurrentContextMenu := _hmgide_CurrentContextMenu + Space(4) + Line + CRLF

			_hmgide_ContextMenuProcessing	:= .T.
			_hmgide_MainMenuProcessing	:= .F.
			_hmgide_NotifyMenuProcessing	:= .F.
			_hmgide_DropDownMenuProcessing	:= .F.

		ElseIf	HMG_UPPER (Line) = 'DEFINE NOTIFY MENU' 

			_hmgide_CurrentNotifyMenu := _hmgide_CurrentNotifyMenu + Space(4) + Line + CRLF

			_hmgide_NotifyMenuProcessing	:= .T.
			_hmgide_ContextMenuProcessing	:= .F.
			_hmgide_MainMenuProcessing	:= .F.
			_hmgide_DropDownMenuProcessing	:= .F.

		ElseIf	HMG_UPPER (Line) = 'DEFINE DROPDOWN MENU' 

			_hmgide_CurrentDropDownMenu := ''

			_hmgide_CurrentDropDownMenu := _hmgide_CurrentDropDownMenu + Space(4) + Line + CRLF

			_hmgide_DropDownMenuProcessing	:= .T.
			_hmgide_NotifyMenuProcessing	:= .F.
			_hmgide_ContextMenuProcessing	:= .F.
			_hmgide_MainMenuProcessing	:= .F.

		ElseIf	HMG_UPPER (Line) = 'END MENU'

			if _hmgide_MainMenuProcessing == .T.
				_hmgide_MainMenuProcessing := .F.
				_hmgide_CurrentMainMenu := _hmgide_CurrentMainMenu + Space(4) + Line + CRLF
				CurrentMenuLevel := 0
			endif

			if _hmgide_ContextMenuProcessing == .T.
				_hmgide_ContextMenuProcessing := .F.
				_hmgide_CurrentContextMenu := _hmgide_CurrentContextMenu + Space(4) + Line + CRLF
				CurrentMenuLevel := 0
			endif

			if _hmgide_NotifyMenuProcessing == .T.
				_hmgide_NotifyMenuProcessing := .F.
				_hmgide_CurrentNotifyMenu := _hmgide_CurrentNotifyMenu + Space(4) + Line + CRLF
				CurrentMenuLevel := 0
			endif

			if _hmgide_DropDownMenuProcessing == .T.
				_hmgide_DropDownMenuProcessing := .F.
				_hmgide_CurrentDropDownMenu := _hmgide_CurrentDropDownMenu + Space(4) + Line + CRLF
				CurrentMenuLevel := 0
				aadd ( _hmgide_aDropDownMenus , _hmgide_CurrentDropDownMenu )
			endif

		ElseIf	HMG_UPPER (Line) = 'DEFINE POPUP ' 

			_hmgide_CurrentMainMenu := _hmgide_CurrentMainMenu + Space(4) + Space(CurrentMenuLevel*4) + Line + CRLF
			CurrentMenuLevel++

		ElseIf	HMG_UPPER (Line) = 'MENUITEM ' 

			if _hmgide_MainMenuProcessing == .T.
				_hmgide_CurrentMainMenu := _hmgide_CurrentMainMenu + Space(4) + Space(CurrentMenuLevel*4) + Line + CRLF
			EndIf

			if _hmgide_ContextMenuProcessing == .T.
				_hmgide_CurrentContextMenu := _hmgide_CurrentContextMenu + Space(8) + Line + CRLF
			EndIf

			if _hmgide_NotifyMenuProcessing == .T.
				_hmgide_CurrentNotifyMenu := _hmgide_CurrentNotifyMenu + Space(8) + Line + CRLF
			EndIf

			if _hmgide_DropDownMenuProcessing == .T.
				_hmgide_CurrentDropDownMenu := _hmgide_CurrentDropDownMenu + Space(8) + Line + CRLF
			EndIf

		ElseIf	HMG_UPPER (Line) = 'SEPARATOR' 

			if _hmgide_MainMenuProcessing == .T.
				_hmgide_CurrentMainMenu := _hmgide_CurrentMainMenu + Space(4) + Space(CurrentMenuLevel*4) + Line + CRLF
			endif

			if _hmgide_ContextMenuProcessing == .T.
				_hmgide_CurrentContextMenu := _hmgide_CurrentContextMenu + Space(4) + Line + CRLF
			EndIf

			if _hmgide_NotifyMenuProcessing == .T.
				_hmgide_CurrentNotifyMenu := _hmgide_CurrentNotifyMenu + Space(4) + Line + CRLF
			EndIf

		ElseIf	HMG_UPPER (Line) = 'END POPUP'

			CurrentMenuLevel--
			_hmgide_CurrentMainMenu := _hmgide_CurrentMainMenu + Space(4) + Space(CurrentMenuLevel*4) + Line + CRLF

		ElseIf	HMG_UPPER (Line) = 'DEFINE STATUSBAR' 

			_hmgide_CurrentStatusBar := _hmgide_CurrentStatusBar + Space(4) + Line + CRLF

			_hmgide_StatusBarProcessing := .T.

		ElseIf	HMG_UPPER (Line) = 'STATUSITEM ' 

			if _hmgide_StatusBarProcessing == .T.
				_hmgide_CurrentStatusBar := _hmgide_CurrentStatusBar + Space(8) + Line + CRLF
			EndIf

		ElseIf	HMG_UPPER (Line) = 'CLOCK' 

			if _hmgide_StatusBarProcessing == .T.
				_hmgide_CurrentStatusBar := _hmgide_CurrentStatusBar + Space(8) + Line + CRLF
			EndIf

		ElseIf	HMG_UPPER (Line) = 'DATE' 

			if _hmgide_StatusBarProcessing == .T.
				_hmgide_CurrentStatusBar := _hmgide_CurrentStatusBar + Space(8) + Line + CRLF
			EndIf

			If	ControlType == 'TEXTBOX'

				CurrentDate := ALLTRIM(HB_USUBSTR ( Line , 6 , HMG_LEN (Line) - 5 ) )

				if ALLTRIM(HMG_UPPER(CurrentDate)) == '.T.'
					__MVPUT( Name + 'DataType' , 'DATE' )
				endif

			EndIf

		ElseIf	HMG_UPPER (Line) = 'KEYBOARD' 

			if _hmgide_StatusBarProcessing == .T.
				_hmgide_CurrentStatusBar := _hmgide_CurrentStatusBar + Space(8) + Line + CRLF
			EndIf

		ElseIf	HMG_UPPER (Line) = 'END STATUSBAR' 

			if _hmgide_StatusBarProcessing == .T.
				_hmgide_CurrentStatusBar := _hmgide_CurrentStatusBar + Space(4) + Line + CRLF
				_hmgide_StatusBarProcessing := .F.
			EndIf

		ElseIf	HMG_UPPER (Line) = 'DEFINE SPLITBOX' 

			_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(4) + Line + CRLF

			_hmgide_SplitBoxProcessing := .T.

		ElseIf	HMG_UPPER (Line) = 'LOAD WINDOW' 

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(8) + Line + CRLF

			else

				ControlType := 'WINDOW'

				* Determine Name
		
				Name := ''
				Started := .F.

				For z := 13 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == ' ' 
						if Started
							Exit
						EndIf
					Else
						if ! Started
							Started := .T.
						EndIf
						Name := Name + Char
					EndIf           	
				Next z

				* Determine Row

				Row := ''		
				a := HB_UAT ( " AT " , HMG_UPPER (Line) )

				if a > 0

					Started := .F.

					For z := a + 4 To HMG_LEN ( Line )
						char := HB_USUBSTR ( Line , z , 1 )
						if char == ' ' 
							if Started
								Exit
							EndIf
						Else
							if ! Started
								Started := .T.
							EndIf
							Row := Row + Char
						EndIf
					Next z

				EndIf

				* Determine Col

				Col := ''		
				a := HB_UAT ( " , " , HMG_UPPER (Line) )

				if a > 0

					Started := .F.

					For z := a + 3 To HMG_LEN ( Line )
						char := HB_USUBSTR ( Line , z , 1 )
						if char == ' ' 
							if Started
								Exit
							EndIf
						Else
							if ! Started
								Started := .T.
							EndIf
							Col := Col + Char
						EndIf
					Next z

				EndIf

				* Determine Width

				xWidth := ''		
				a := HB_UAT ( " WIDTH " , HMG_UPPER (Line) )

				if a > 0

					Started := .F.

					For z := a + 7 To HMG_LEN ( Line )
						char := HB_USUBSTR ( Line , z , 1 )
						if char == ' ' 
							if Started
								Exit
							EndIf
						Else
							if ! Started
								Started := .T.
							EndIf
							xWidth := xWidth + Char
						EndIf
					Next z

				EndIf

				* Determine Height

				xHeight := ''		
				a := HB_UAT ( " HEIGHT " , HMG_UPPER (Line) )

				if a > 0
					xHeight := HB_USUBSTR ( Line , a + 7 , 255 )
				Else
					xHeight := ''
				EndIf


				@ VAL(Row)  , VAL(Col) LABEL &Name ;
					OF &DesignForm ;
					VALUE Name ACTION SelectControl (This.Name) ;
					WIDTH VAL(xWidth) HEIGHT VAL(xHeight) ;
					BORDER

				w := GetControlIndex ( Name , DesignForm )
				_HMG_SYSDATA [ 39 ] [w] := 8

				CurrentWidth	:= -1
				CurrentHeight	:= -1

			endif


		ElseIf	HMG_UPPER (Line) = 'END SPLITBOX' 

			_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(4) + Line + CRLF

			_hmgide_SplitBoxProcessing := .F.

		ElseIf	HMG_UPPER (Line) = 'DEFINE BUTTON'
			ControlType := 'BUTTON'
			Name := HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 )

			__MVPUBLIC ( Name + 'Caption' ) 
			__MVPUT( Name + 'Caption' , Name )
			__MVPUBLIC ( Name + 'Action' ) 
			__MVPUT( Name + 'Action' , 'Nil' )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'Flat' ) 
			__MVPUT( Name + 'Flat' , '.F.' )
			__MVPUBLIC ( Name + 'TabStop' ) 
			__MVPUT( Name + 'TabStop' , '.T.' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'Transparent' ) 
			__MVPUT( Name + 'Transparent' , '.F.' )
			__MVPUBLIC ( Name + 'Picture' ) 
			__MVPUT( Name + 'Picture' , '' )
			__MVPUBLIC ( Name + 'OnGotFocus' ) 
			__MVPUT( Name + 'OnGotFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'OnLostFocus' ) 
			__MVPUT( Name + 'OnLostFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'PictAlignment' ) 
			__MVPUT( Name + 'PictAlignment' , 'TOP' )
			__MVPUBLIC ( Name + 'MultiLine' ) 
			__MVPUT( Name + 'MultiLine' , '.F.' )


			DEFINE BUTTON &Name
			PARENT &DesignForm
			ON GOTFOCUS SelectControl( This.Name )
		ElseIf	HMG_UPPER (Line) = 'DEFINE CHECKBOX'
			ControlType := 'CHECKBOX'
			Name := HB_USUBSTR ( Line , 17 , HMG_LEN (Line) - 16 )
			DEFINE CHECKBOX &Name
			PARENT &DesignForm
			ONCHANGE SelectControl (This.Name)

			__MVPUBLIC ( Name + 'Caption' ) 
			__MVPUT( Name + 'Caption' , Name )
			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , '.F.' )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'OnChange' ) 
			__MVPUT( Name + 'OnChange' , 'Nil' )
			__MVPUBLIC ( Name + 'OnGotFocus' ) 
			__MVPUT( Name + 'OnGotFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'OnLostFocus' ) 
			__MVPUT( Name + 'OnLostFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'Field' ) 
			__MVPUT( Name + 'Field' , 'Nil' )
			__MVPUBLIC ( Name + 'BackColor' ) 
			__MVPUT( Name + 'BackColor' , '' )
			__MVPUBLIC ( Name + 'FontColor' ) 
			__MVPUT( Name + 'FontColor' , '' )
			__MVPUBLIC ( Name + 'TabStop' ) 
			__MVPUT( Name + 'TabStop' , '.T.' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'Transparent' ) 
			__MVPUT( Name + 'Transparent' , '.F.' )

		ElseIf	HMG_UPPER (Line) = 'DEFINE LISTBOX'
			ControlType := 'LISTBOX'
			Name := HB_USUBSTR ( Line , 16 , HMG_LEN (Line) - 15 )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(8) + Line + CRLF

			else

				DEFINE LISTBOX &Name
				PARENT &DesignForm
				ITEMS { Name }
				ON GOTFOCUS SelectControl ( This.Name )

			endif

			__MVPUBLIC ( Name + 'Items' ) 
			__MVPUT( Name + 'Items' , '{""}' )
			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , '0' )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'OnChange' ) 
			__MVPUT( Name + 'OnChange' , 'Nil' )
			__MVPUBLIC ( Name + 'OnGotFocus' ) 
			__MVPUT( Name + 'OnGotFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'OnLostFocus' ) 
			__MVPUT( Name + 'OnLostFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'BackColor' ) 
			__MVPUT( Name + 'BackColor' , '' )
			__MVPUBLIC ( Name + 'FontColor' ) 
			__MVPUT( Name + 'FontColor' , '' )
			__MVPUBLIC ( Name + 'OnDblClick' ) 
			__MVPUT( Name + 'OnDblClick' , 'Nil' )
			__MVPUBLIC ( Name + 'TabStop' ) 
			__MVPUT( Name + 'TabStop' , '.T.' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'Sort' ) 
			__MVPUT( Name + 'Sort' , '.F.' )
			__MVPUBLIC ( Name + 'MultiSelect' )
 			__MVPUT( Name + 'MultiSelect' , '.F.' )
			__MVPUBLIC ( Name + 'Break' ) 
			__MVPUT( Name + 'Break' , '.F.' )
			__MVPUBLIC ( Name + 'DragItems' ) 
			__MVPUT( Name + 'DragItems' , '.F.' )

		ElseIf	HMG_UPPER (Line) = 'DEFINE COMBOBOX'
			ControlType := 'COMBOBOX'
			Name := HB_USUBSTR ( Line , 17 , HMG_LEN (Line) - 16 )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(8) + Line + CRLF

			else

				DEFINE COMBOBOX &Name
				PARENT &DesignForm
				ITEMS { Name }			
				VALUE 1
				ONGOTFOCUS SelectControl ( This.Name )

			endif

			__MVPUBLIC ( Name + 'Items' ) 
			__MVPUT( Name + 'Items' , '{""}' )
			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , '0' )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'OnChange' ) 
			__MVPUT( Name + 'OnChange' , 'Nil' )
			__MVPUBLIC ( Name + 'OnGotFocus' ) 
			__MVPUT( Name + 'OnGotFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'OnLostFocus' ) 
			__MVPUT( Name + 'OnLostFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'TabStop' ) 
			__MVPUT( Name + 'TabStop' , '.T.' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'Sort' ) 
			__MVPUT( Name + 'Sort' , '.F.' )
			__MVPUBLIC ( Name + 'OnEnter' ) 
			__MVPUT( Name + 'OnEnter' , 'Nil' )
			__MVPUBLIC ( Name + 'OnDisplayChange' ) 
			__MVPUT( Name + 'OnDisplayChange' , 'Nil' )
			__MVPUBLIC ( Name + 'DisplayEdit' ) 
			__MVPUT( Name + 'DisplayEdit' , '.F.' )
			__MVPUBLIC ( Name + 'ValueSource' ) 
			__MVPUT( Name + 'ValueSource' , '' )
			__MVPUBLIC ( Name + 'ItemSource' ) 
			__MVPUT( Name + 'ItemSource' , 'Nil' )
			__MVPUBLIC ( Name + 'Break' ) 
			__MVPUT( Name + 'Break' , '.F.' )

			__MVPUBLIC ( Name + 'DroppedWidth' ) 
			__MVPUT( Name + 'DroppedWidth' , 'Nil' )
			__MVPUBLIC ( Name + 'Image' ) 
			__MVPUT( Name + 'Image' , 'Nil' )
			__MVPUBLIC ( Name + 'OnDropDown' ) 
			__MVPUT( Name + 'OnDropDown' , 'Nil' )
			__MVPUBLIC ( Name + 'OnCloseUp' ) 
			__MVPUT( Name + 'OnCloseUp' , 'Nil' )


		ElseIf	HMG_UPPER (Line) = 'DEFINE CHECKBUTTON'
			ControlType := 'CHECKBUTTON'
			Name := HB_USUBSTR ( Line , 20 , HMG_LEN (Line) - 19 )
			DEFINE CHECKBUTTON &Name
			PARENT &DesignForm
			ONCHANGE SelectControl (This.name)
			CAPTION Name

			__MVPUBLIC ( Name + 'Caption' ) 
			__MVPUT( Name + 'Caption' , Name )
			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , '.F.' )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'OnChange' ) 
			__MVPUT( Name + 'OnChange' , 'Nil' )
			__MVPUBLIC ( Name + 'OnGotFocus' ) 
			__MVPUT( Name + 'OnGotFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'OnLostFocus' ) 
			__MVPUT( Name + 'OnLostFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'TabStop' ) 
			__MVPUT( Name + 'TabStop' , '.T.' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'Picture' ) 
			__MVPUT( Name + 'Picture' , '' )

		ElseIf	HMG_UPPER (Line) = 'DEFINE GRID'
			ControlType := 'GRID'
			Name := HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(8) + Line + CRLF

			else

				DEFINE GRID &Name
				PARENT &DesignForm
				ONGOTFOCUS SelectControl(This.name)
				HEADERS { '' , '' , '' }
				WIDTHS { 90 , 90 , 90 }
				ITEMS { { Name , '' , '' } }

			endif

			__MVPUBLIC ( Name + 'Items' ) 
			__MVPUT( Name + 'Items' , '{""}' )
			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , '0' )
			__MVPUBLIC ( Name + 'Widths' ) 
			__MVPUT( Name + 'Widths' , '{}' )
			__MVPUBLIC ( Name + 'Headers' ) 
			__MVPUT( Name + 'Headers' , '{}' )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'OnChange' ) 
			__MVPUT( Name + 'OnChange' , 'Nil' )
			__MVPUBLIC ( Name + 'OnGotFocus' ) 
			__MVPUT( Name + 'OnGotFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'OnLostFocus' ) 
			__MVPUT( Name + 'OnLostFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'OnDblClick' ) 
			__MVPUT( Name + 'OnDblClick' , 'Nil' )
			__MVPUBLIC ( Name + 'OnHeadClick' ) 
			__MVPUT( Name + 'OnHeadClick' , 'Nil' )
			__MVPUBLIC ( Name + 'OnQueryData' ) 
			__MVPUT( Name + 'OnQueryData' , 'Nil' )
			__MVPUBLIC ( Name + 'MultiSelect' )
			__MVPUT( Name + 'MultiSelect' , '.F.' )
			__MVPUBLIC ( Name + 'AllowEdit' ) 
			__MVPUT( Name + 'AllowEdit' , '.F.' )
			__MVPUBLIC ( Name + 'Virtual' ) 
			__MVPUT( Name + 'Virtual' , '.F.' )
			__MVPUBLIC ( Name + 'Lines' ) 
			__MVPUT( Name + 'Lines' , '.T.' )
			__MVPUBLIC ( Name + 'Image' ) 
			__MVPUT( Name + 'Image' , 'Nil' )
			__MVPUBLIC ( Name + 'Justify' ) 
			__MVPUT( Name + 'Justify' , 'Nil' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'ItemCount' ) 
			__MVPUT( Name + 'ItemCount' , 'Nil' )
			__MVPUBLIC ( Name + 'BackColor' ) 
			__MVPUT( Name + 'BackColor' , '' )
			__MVPUBLIC ( Name + 'FontColor' ) 
			__MVPUT( Name + 'FontColor' , '' )

			__MVPUBLIC ( Name + 'DynamicBackColor' ) 
			__MVPUT( Name + 'DynamicBackColor' , 'Nil' )

			__MVPUBLIC ( Name + 'DynamicForeColor' ) 
			__MVPUT( Name + 'DynamicForeColor' , 'Nil' )
	
			__MVPUBLIC ( Name + 'ColumnWhen' ) 
			__MVPUT( Name + 'ColumnWhen' , 'Nil' )

			__MVPUBLIC ( Name + 'ColumnValid' ) 
			__MVPUT( Name + 'ColumnValid' , 'Nil' )

			__MVPUBLIC ( Name + 'ColumnControls' ) 
			__MVPUT( Name + 'ColumnControls' , 'Nil' )

			__MVPUBLIC ( Name + 'ShowHeaders' ) 
			__MVPUT( Name + 'ShowHeaders' , '.T.' )

			__MVPUBLIC ( Name + 'Break' ) 
			__MVPUT( Name + 'Break' , '.F.' )

			__MVPUBLIC ( Name + 'HeaderImages' ) 
			__MVPUT( Name + 'HeaderImages' , 'Nil' )

			__MVPUBLIC ( Name + 'CellNavigation' ) 
			__MVPUT( Name + 'CellNavigation' , '.F.' )



			__MVPUBLIC ( Name + 'RowSource' ) 
			__MVPUT( Name + 'RowSource' , 'Nil' )

			__MVPUBLIC ( Name + 'ColumnFields' ) 
			__MVPUT( Name + 'ColumnFields' , 'Nil' )

			__MVPUBLIC ( Name + 'AllowAppend' ) 
			__MVPUT( Name + 'AllowAppend' , '.F.' )

			__MVPUBLIC ( Name + 'AllowDelete' ) 
			__MVPUT( Name + 'AllowDelete' , '.F.' )

			__MVPUBLIC ( Name + 'Buffered' ) 
			__MVPUT( Name + 'Buffered' , '.F.' )

			__MVPUBLIC ( Name + 'DynamicDisplay' ) 
			__MVPUT( Name + 'DynamicDisplay' , '.F.' )

			__MVPUBLIC ( Name + 'OnSave' ) 
			__MVPUT( Name + 'OnSave' , 'Nil' )

			__MVPUBLIC ( Name + 'LockColumns' ) 
			__MVPUT( Name + 'LockColumns' , 'Nil' )



		ElseIf	HMG_UPPER (Line) = 'DEFINE SLIDER'
			ControlType := 'SLIDER'
			Name := HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 )
			DEFINE SLIDER &Name
			PARENT &DesignForm
			ONCHANGE SelectControl (This.Name)
			RANGEMIN 1
			RANGEMAX 10			

			__MVPUBLIC ( Name + 'RangeMax' ) 
			__MVPUT( Name + 'RangeMax' , '1' )
			__MVPUBLIC ( Name + 'RangeMin' ) 
			__MVPUT( Name + 'RangeMin' , '10' )
			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , '0' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'OnChange' ) 
			__MVPUT( Name + 'OnChange' , 'Nil' )
			__MVPUBLIC ( Name + 'TabStop' ) 
			__MVPUT( Name + 'TabStop' , '.T.' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'TickMarks' ) 
			__MVPUT( Name + 'TickMarks' , 'BOTTOM' )
			__MVPUBLIC ( Name + 'Orientation' ) 
			__MVPUT( Name + 'Orientation' , 'HORIZONTAL' )
			__MVPUBLIC ( Name + 'BackColor' ) 
			__MVPUT( Name + 'BackColor' , '' )

		ElseIf	HMG_UPPER (Line) = 'DEFINE SPINNER'
			ControlType := 'SPINNER'
			Name := HB_USUBSTR ( Line , 16 , HMG_LEN (Line) - 15 )
			DEFINE SPINNER &Name
			PARENT &DesignForm
			VALUE 5
			RANGEMIN 1
			RANGEMAX 10
			ONGOTFOCUS SelectControl (This.Name)

			__MVPUBLIC ( Name + 'RangeMax' ) 
			__MVPUT( Name + 'RangeMax' , '1' )
			__MVPUBLIC ( Name + 'RangeMin' ) 
			__MVPUT( Name + 'RangeMin' , '10' )
			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , '0' )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'OnChange' ) 
			__MVPUT( Name + 'OnChange' , 'Nil' )
			__MVPUBLIC ( Name + 'OnGotFocus' ) 
			__MVPUT( Name + 'OnGotFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'OnLostFocus' ) 
			__MVPUT( Name + 'OnLostFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'TabStop' ) 
			__MVPUT( Name + 'TabStop' , '.T.' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'BackColor' ) 
			__MVPUT( Name + 'BackColor' , '' )
			__MVPUBLIC ( Name + 'FontColor' ) 
			__MVPUT( Name + 'FontColor' , '' )
			__MVPUBLIC ( Name + 'Wrap' ) 
			__MVPUT( Name + 'Wrap' , '.F.' )
			__MVPUBLIC ( Name + 'ReadOnly' ) 
			__MVPUT( Name + 'ReadOnly' , '.F.' )

			__MVPUBLIC ( Name + 'Increment' ) 
			__MVPUT( Name + 'Increment' , '1' )

		ElseIf	HMG_UPPER (Line) = 'DEFINE IMAGE'
			ControlType := 'IMAGE'
			Name := HB_USUBSTR ( Line , 14 , HMG_LEN (Line) - 13 )
			DEFINE IMAGE &Name
			PARENT &DesignForm
			ACTION SelectControl (This.name)
			PICTURE 'demo'
			STRETCH .T.

			__MVPUBLIC ( Name + 'Picture' ) 
			__MVPUT( Name + 'Picture' , '' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'Stretch' ) 
			__MVPUT( Name + 'Stretch' , '.F.' )
			__MVPUBLIC ( Name + 'Action' ) 
			__MVPUT( Name + 'Action' , 'Nil' )

		ElseIf	HMG_UPPER (Line) = 'DEFINE TREE'
			ControlType := 'TREE'

			* Determine Name
		
			Name := ''
			Started := .F.

			For z := 13 To HMG_LEN ( Line )
				char := HB_USUBSTR ( Line , z , 1 )
				if char == ' ' 
					if Started
						Exit
					EndIf
				Else
					if ! Started
						Started := .T.
					EndIf
					Name := Name + Char
				EndIf           	
			Next z

			* Determine Row & Col

			a := HB_UAT ( " AT " , HMG_UPPER (Line) )
			c := HB_UAT ( "," , HMG_UPPER (Line) )
			Row := HB_USUBSTR ( Line , a + 4 , c - a - 4 )
			Col := ''			
			Started := .F.

			For z := c + 1 To HMG_LEN ( Line )
				char := HB_USUBSTR ( Line , z , 1 )
				if char == ' ' 
					if Started
						Exit
					EndIf
				Else
					if ! Started
						Started := .T.
					EndIf
					Col := Col + Char
				EndIf
			Next z

			* Determine Width
		
			a := HB_UAT ( " WIDTH " , HMG_UPPER (Line) )

			if a > 0

				Width := ''
				Started := .F.

				For z := a + 6 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == ' ' 
						if Started
							Exit
						EndIf
					Else
						if ! Started
							Started := .T.
						EndIf
						Width := Width + Char
					EndIf
				Next z

			EndIf

			* Determine Height
		
			a := HB_UAT ( " HEIGHT " , HMG_UPPER (Line) )

			if a > 0
			
				Height := ''
				Started := .F.

				For z := a + 7 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == ' ' 
						if Started
							Exit
						EndIf
					Else
						if ! Started
							Started := .T.
						EndIf
						Height := Height + Char
					EndIf           	
				Next z

			endif

			* Determine Value

			Value := ''
		
			a := HB_UAT ( " VALUE " , HMG_UPPER (Line) )

			if a > 0
			
				Started := .F.

				For z := a + 6 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == ' ' 
						if Started
							Exit
						EndIf
					Else
						if ! Started
							Started := .T.
						EndIf
						Value := Value + Char
					EndIf           	
				Next z

			endif

			__MVPUBLIC ( Name + 'Value' ) 

			If Empty ( value )
				__MVPUT( Name + 'Value' , '0' )
			Else
				__MVPUT( Name + 'Value' , Value )
			EndIf

			* Determine FontName
		
			a := HB_UAT ( " FONT " , HMG_UPPER (Line) )

			FontName := ''

			if a > 0
			
				Started := .F.

				For z := a + 5 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == ' ' 
						if Started
							Exit
						EndIf
					Else
						if ! Started
							Started := .T.
						EndIf
						FontName := FontName + Char
					EndIf           	
				Next z

			endif

			Fontname := ALLTRIM ( FontName )

			if	HB_ULEFT ( Fontname , 1 ) == '"' ;
				.or. ;
				HB_ULEFT ( Fontname , 1 ) == "'" 

				Fontname := HB_URIGHT ( Fontname , HMG_LEN( Fontname ) - 1 )

			EndIf

			if	HB_URIGHT ( Fontname , 1 ) == '"' ;
				.or. ;
				HB_URIGHT ( Fontname , 1 ) == "'"

				Fontname := HB_ULEFT ( Fontname , HMG_LEN( Fontname ) - 1 )

			EndIf

			if Empty ( FontName )
				FontName := 'Arial'
			EndIf

			* Determine FontSize
		
			a := HB_UAT ( " SIZE " , HMG_UPPER (Line) )

			FontSize := ''

			if a > 0
			
				Started := .F.

				For z := a + 5 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == ' ' 
						if Started
							Exit
						EndIf
					Else
						if ! Started
							Started := .T.
						EndIf
						FontSize := FontSize + Char
					EndIf           	
				Next z

			endif

			FontSize := ALLTRIM ( FontSize )

			if Empty ( FontSize )
				FontSize := '9'
			EndIf

			__MVPUBLIC( Name + 'FontName' )
			__MVPUBLIC( Name + 'FontSize' )

			__MVPUT( Name + 'FontName' , FontName )
			__MVPUT( Name + 'FontSize' ,  FontSize )

			* Determine ToolTip
		
			a := HB_UAT ( " TOOLTIP " , HMG_UPPER (Line) )

			ToolTip := ''

			if a > 0

				Started := .F.

				For z := a + 9 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == '"' 
						if Started
							Exit
						Else
							Started := .T.
						EndIf
					Else
						if Started
							ToolTip := ToolTip + Char
						EndIf
					EndIf
				Next z

			EndIf

			ToolTip := ALLTRIM(ToolTip)

			if	HB_ULEFT ( ToolTip , 1 ) == '"' ;
				.or. ;
				HB_ULEFT ( ToolTip , 1 ) == "'" 

				ToolTip := HB_URIGHT ( ToolTip , HMG_LEN( ToolTip ) - 1 )

			EndIf

			if	HB_URIGHT ( ToolTip, 1 ) == '"' ;
				.or. ;
				HB_URIGHT ( ToolTip , 1 ) == "'"

				ToolTip := HB_ULEFT ( ToolTip , HMG_LEN( ToolTip ) - 1 )

			EndIf

			ToolTip := ALLTRIM(ToolTip)

			* Determine OnGotFocus
		
			a := HB_UAT ( " ON GOTFOCUS " , HMG_UPPER (Line) )

			OnGotFocus := ''

			if a > 0

				Started := .F.

				For z := a + 13 To HMG_LEN ( Line )

					NextToken := HB_USUBSTR ( Line , z , 9 )
					if NextToken == 'ON CHANGE'
						Exit
					endif

					NextToken := HB_USUBSTR ( Line , z , 12 )
					if NextToken == 'ON LOSTFOCUS'
						Exit
					endif

					char := HB_USUBSTR ( Line , z , 1 )

					OnGotFocus := OnGotFocus + Char

				Next z

				OnGotFocus := ALLTRIM(OnGotFocus)

				if Empty (OnGotFocus)
					OnGotFocus := 'Nil'
				EndIf
        
			EndIf

			* Determine OnChange
		
			a := HB_UAT ( " ON CHANGE " , HMG_UPPER (Line) )

			OnChange := ''

			if a > 0

				Started := .F.

				For z := a + 11 To HMG_LEN ( Line )

					NextToken := HB_USUBSTR ( Line , z , 12 )

					if NextToken == 'ON LOSTFOCUS'
						Exit
					endif

					char := HB_USUBSTR ( Line , z , 1 )

					OnChange := OnChange + Char

				Next z

				OnChange := ALLTRIM(OnChange)

				if Empty (OnChange)
					OnChange := 'Nil'
				EndIf
        
			EndIf

			* Determine OnLostFocus
		
			a := HB_UAT ( " ON LOSTFOCUS " , HMG_UPPER (Line) )

			OnLostFocus := ''

			if a > 0

				Started := .F.

				For z := a + 14 To HMG_LEN ( Line )

					NextToken := HB_USUBSTR ( Line , z , 11 )

					if NextToken == 'ON DBLCLICK'
						Exit
					endif

					char := HB_USUBSTR ( Line , z , 1 )

					OnLostFocus := OnLostFocus + Char

				Next z

				OnLostFocus := ALLTRIM(OnLostFocus)

				if Empty (OnLostFocus)
					OnLostFocus := 'Nil'
				EndIf
        
			EndIf

			* Determine OnDblClick
		
			a := HB_UAT ( " ON DBLCLICK " , HMG_UPPER (Line) )

			OnDblClick := ''

			if a > 0

				Started := .F.

				For z := a + 13 To HMG_LEN ( Line )

					NextToken := HB_USUBSTR ( Line , z , 10 )

					if NextToken == 'NODEIMAGES'
						Exit
					endif

					char := HB_USUBSTR ( Line , z , 1 )

					OnDblClick := OnDblClick + Char

				Next z

				OnDblClick := ALLTRIM(OnDblClick)

				if Empty (OnDblClick)
					OnDblClick := 'Nil'
				EndIf
        
			EndIf

			* Determine NodeImages
		
			a := HB_UAT ( " NODEIMAGES " , HMG_UPPER (Line) )

			NodeImages := ''

			if a > 0

				Started := .F.

				For z := a + 12 To HMG_LEN ( Line )

					NextToken := HB_USUBSTR ( Line , z , 10 )

					if NextToken == 'ITEMIMAGES'
						Exit
					endif

					char := HB_USUBSTR ( Line , z , 1 )

					NodeImages := NodeImages + Char

				Next z

				NodeImages := ALLTRIM(NodeImages)

				if Empty (NodeImages)
					NodeImages := 'Nil'
				EndIf
        
			EndIf

			* Determine ItemImages
		
			a := HB_UAT ( " ITEMIMAGES " , HMG_UPPER (Line) )

			ItemImages := ''

			if a > 0

				Started := .F.

				For z := a + 12 To HMG_LEN ( Line )

					NextToken := HB_USUBSTR ( Line , z , 12 )
					if NextToken == 'NOROOTBUTTON'
						Exit
					endif
					NextToken := HB_USUBSTR ( Line , z , 7 )
					if NextToken == 'ITEMIDS'
						Exit
					endif
					NextToken := HB_USUBSTR ( Line , z , 6 )
					if NextToken == 'HELPID'
						Exit
					endif

					char := HB_USUBSTR ( Line , z , 1 )

					ItemImages := ItemImages + Char

				Next z

				ItemImages := ALLTRIM(ItemImages)

				if Empty (ItemImages)
					ItemImages := 'Nil'
				EndIf
        
			EndIf

			* Determine RootButton

			__MVPUBLIC ( Name + 'RootButton' ) 
		
			a := HB_UAT ( " NOROOTBUTTON" , HMG_UPPER (Line) )

			if a != 0
				__MVPUT( Name + 'RootButton' , '.F.' )
			else
				__MVPUT( Name + 'RootButton' , '.T.' )
			endif

			* Determine ItemIds

			__MVPUBLIC ( Name + 'ItemIds' ) 
		
			a := HB_UAT ( " ITEMIDS" , HMG_UPPER (Line) )

			if a != 0
				__MVPUT( Name + 'ItemIds' , '.T.' )
			else
				__MVPUT( Name + 'ItemIds' , '.F.' )
			endif

			* Determine HelpId
		
			a := HB_UAT ( " HELPID " , HMG_UPPER (Line) )

			HelpId := ''

			if a > 0

				Started := .F.

				For z := a + 8 To HMG_LEN ( Line )

					char := HB_USUBSTR ( Line , z , 1 )

					HelpId := HelpId + Char

				Next z

				HelpId := ALLTRIM(HelpId)

				if Empty (HelpId)
					HelpId := 'Nil'
				EndIf
        
			EndIf

			*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-

			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , HelpId )

			__MVPUBLIC ( Name + 'ItemImages' ) 
			__MVPUT( Name + 'ItemImages' , ItemImages )

			__MVPUBLIC ( Name + 'NodeImages' ) 
			__MVPUT( Name + 'NodeImages' , NodeImages )

			__MVPUBLIC ( Name + 'OnDblClick' ) 
			__MVPUT( Name + 'OnDblClick' , OnDblClick )

			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , ToolTip )

			__MVPUBLIC ( Name + 'OnGotFocus' ) 
			__MVPUT( Name + 'OnGotFocus' , OnGotFocus )

			__MVPUBLIC ( Name + 'OnChange' ) 
			__MVPUT( Name + 'OnChange' , OnChange )

			__MVPUBLIC ( Name + 'OnLostFocus' ) 
			__MVPUT( Name + 'OnLostFocus' , OnLostFocus )

			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUBLIC ( Name + 'FontUnderLine' ) 


			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(8) + Line + CRLF

				__MVPUBLIC ( Name + 'Row' ) 
				__MVPUT( Name + 'Row' , 'Nil' )

				__MVPUBLIC ( Name + 'Col' ) 
				__MVPUT( Name + 'Col' , 'Nil' )

				__MVPUBLIC ( Name + 'Break' ) 
				__MVPUT( Name + 'Break' , '.F.' )

				__MVPUBLIC ( Name + 'Width' ) 
				__MVPUT( Name + 'Width' , Width )
				__MVPUBLIC ( Name + 'Height' ) 
				__MVPUT( Name + 'Height' , Height )

			else

				*

				if	Empty (Width) .and. Empty (Height)

					DEFINE TREE &Name OF &DesignForm AT VAL (Row) , VAL (Col) FONT Fontname SIZE VAL(FontSize) ON GOTFOCUS SelectControl( This.Name ) 

				ElseIf Empty (Width) .and. !Empty (Height)

					DEFINE TREE &Name OF &DesignForm AT VAL (Row) , VAL (Col) HEIGHT VAL ( Height )  FONT Fontname SIZE VAL(FontSize) ON GOTFOCUS SelectControl( This.Name )

				ElseIf !Empty (Width) .and. Empty (Height)

					DEFINE TREE &Name OF &DesignForm AT VAL (Row) , VAL (Col) WIDTH VAL ( Width )  FONT Fontname SIZE VAL(FontSize) ON GOTFOCUS SelectControl( This.Name )

				ElseIf !Empty (Width) .and. !Empty (Height)

					DEFINE TREE &Name OF &DesignForm AT VAL (Row) , VAL (Col) WIDTH VAL ( Width ) HEIGHT VAL ( Height )  FONT Fontname SIZE VAL(FontSize) ON GOTFOCUS SelectControl( This.Name )

				EndIf

				NODE Name
				END NODE

			endif

			* Determine Bold
			a := HB_UAT ( " BOLD" , HMG_UPPER (Line) )
			if a > 0
				__MVPUT( Name + 'FontBold' , '.T.' )
				SetProperty ( DesignForm , Name , 'FontBold' , .T. )
			else
				__MVPUT( Name + 'FontBold' , '.F.' )
			endif
			* Determine Italic
			a := HB_UAT ( " ITALIC" , HMG_UPPER (Line) )
			if a > 0
				SetProperty ( DesignForm , Name , 'FontItalic' , .T. )
				__MVPUT( Name + 'FontItalic' , '.T.' )
			else
				__MVPUT( Name + 'FontItalic' , '.F.' )
			endif
			* Determine UnderLine
			a := HB_UAT ( " UNDERLINE" , HMG_UPPER (Line) )
			if a > 0
				SetProperty ( DesignForm , Name , 'FontUnderLine' , .T. )
				__MVPUT( Name + 'FontUnderLine' , '.T.' )
			else
				__MVPUT( Name + 'FontUnderLine' , '.F.' )
			endif
			* Determine StrikeOut
			a := HB_UAT ( " STRIKEOUT" , HMG_UPPER (Line) )
			if a > 0
				SetProperty ( DesignForm , Name , 'FontStrikeOut' , .T. )
				__MVPUT( Name + 'FontStrikeOut' , '.T.' )
			else
				__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			endif

		ElseIf	HMG_UPPER (Line) = 'DEFINE DATEPICKER'
			ControlType := 'DATEPICKER'
			Name := HB_USUBSTR ( Line , 19 , HMG_LEN (Line) - 18 )
			DEFINE DATEPICKER &Name
			PARENT &DesignForm
			ONGOTFOCUS SelectControl(This.Name)

			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , 'CTOD(  /  /  )' )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'OnChange' ) 
			__MVPUT( Name + 'OnChange' , 'Nil' )
			__MVPUBLIC ( Name + 'OnGotFocus' ) 
			__MVPUT( Name + 'OnGotFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'OnLostFocus' ) 
			__MVPUT( Name + 'OnLostFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'OnEnter' ) 
			__MVPUT( Name + 'OnEnter' , 'Nil' )
			__MVPUBLIC ( Name + 'TabStop' ) 
			__MVPUT( Name + 'TabStop' , '.T.' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'ShowNone' ) 
			__MVPUT( Name + 'ShowNone' , '.F.' )
			__MVPUBLIC ( Name + 'UpDown' ) 
			__MVPUT( Name + 'UpDown' , '.F.' )
			__MVPUBLIC ( Name + 'RightAlign' ) 
			__MVPUT( Name + 'RightAlign' , '.F.' )
			__MVPUBLIC ( Name + 'Field' ) 
			__MVPUT( Name + 'Field' , 'Nil' )

		ElseIf	HMG_UPPER (Line) = 'DEFINE TEXTBOX'
			ControlType := 'TEXTBOX'
			Name := HB_USUBSTR ( Line , 16 , HMG_LEN (Line) - 15 )
			DEFINE TEXTBOX &Name
			PARENT &DesignForm
			VALUE Name
			ON GOTFOCUS SelectControl( This.Name )

			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , '' )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'OnChange' ) 
			__MVPUT( Name + 'OnChange' , 'Nil' )
			__MVPUBLIC ( Name + 'OnGotFocus' ) 
			__MVPUT( Name + 'OnGotFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'OnLostFocus' ) 
			__MVPUT( Name + 'OnLostFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'InputMask' ) 
			__MVPUT( Name + 'InputMask' , '' )
			__MVPUBLIC ( Name + 'Format' ) 
			__MVPUT( Name + 'Format' , '' )
			__MVPUBLIC ( Name + 'DataType' ) 
			__MVPUT( Name + 'DataType' , 'CHARACTER' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'OnEnter' ) 
			__MVPUT( Name + 'OnEnter' , 'Nil' )
			__MVPUBLIC ( Name + 'Field' ) 
			__MVPUT( Name + 'Field' , 'Nil' )
			__MVPUBLIC ( Name + 'BackColor' ) 
			__MVPUT( Name + 'BackColor' , '' )
			__MVPUBLIC ( Name + 'FontColor' ) 
			__MVPUT( Name + 'FontColor' , '' )
			__MVPUBLIC ( Name + 'TabStop' ) 
			__MVPUT( Name + 'TabStop' , '.T.' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'ReadOnly' ) 
			__MVPUT( Name + 'ReadOnly' , '.F.' )
			__MVPUBLIC ( Name + 'RightAlign' ) 
			__MVPUT( Name + 'RightAlign' , '.F.' )
			__MVPUBLIC ( Name + 'MaxLength' ) 
			__MVPUT( Name + 'MaxLength' , 'Nil' )
			__MVPUBLIC ( Name + 'Password' ) 
			__MVPUT( Name + 'Password' , '.F.' )
			__MVPUBLIC ( Name + 'CaseConvert' ) 
			__MVPUT( Name + 'CaseConvert' , 'NONE' )
			__MVPUBLIC ( Name + 'DisabledBackColor' ) 
			__MVPUT( Name + 'DisabledBackColor' , 'Nil' )
			__MVPUBLIC ( Name + 'DisabledFontColor' ) 
			__MVPUT( Name + 'DisabledFontColor' , 'Nil' )


		ElseIf	HMG_UPPER (Line) = 'DEFINE EDITBOX'
			ControlType := 'EDITBOX'
			Name := HB_USUBSTR ( Line , 16 , HMG_LEN (Line) - 15 )

			currenthscrollbar := ''
			currentvscrollbar := ''

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(8) + Line + CRLF

			else

				DEFINE EDITBOX &Name
				PARENT &DesignForm
				ON GOTFOCUS SelectControl (This.Name)
				VALUE Name

			endif

			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , '' )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'OnChange' ) 
			__MVPUT( Name + 'OnChange' , 'Nil' )
			__MVPUBLIC ( Name + 'OnGotFocus' ) 
			__MVPUT( Name + 'OnGotFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'OnLostFocus' ) 
			__MVPUT( Name + 'OnLostFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'BackColor' ) 
			__MVPUT( Name + 'BackColor' , 'Nil' )
			__MVPUBLIC ( Name + 'FontColor' ) 
			__MVPUT( Name + 'FontColor' , 'Nil' )
			__MVPUBLIC ( Name + 'TabStop' ) 
			__MVPUT( Name + 'TabStop' , '.T.' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'Field' ) 
			__MVPUT( Name + 'Field' , 'Nil' )
			__MVPUBLIC ( Name + 'MaxLength' ) 
			__MVPUT( Name + 'MaxLength' , 'Nil' )
			__MVPUBLIC ( Name + 'ReadOnly' ) 
			__MVPUT( Name + 'ReadOnly' , '.F.' )
			__MVPUBLIC ( Name + 'hScrollBar' ) 
			__MVPUT( Name + 'hScrollBar' , '.T.' )
			__MVPUBLIC ( Name + 'vScrollBar' ) 
			__MVPUT( Name + 'vScrollBar' , '.T.' )
			__MVPUBLIC ( Name + 'Break' ) 
			__MVPUT( Name + 'Break' , '.F.' )
			__MVPUBLIC ( Name + 'DisabledBackColor' ) 
			__MVPUT( Name + 'DisabledBackColor' , 'Nil' )
			__MVPUBLIC ( Name + 'DisabledFontColor' ) 
			__MVPUT( Name + 'DisabledFontColor' , 'Nil' )


		ElseIf	HMG_UPPER (Line) = 'DEFINE LABEL'
			ControlType := 'LABEL'
			Name := HB_USUBSTR ( Line , 14 , HMG_LEN (Line) - 13 )
			DEFINE LABEL &Name
			PARENT &DesignForm
			VALUE Name

			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , '' )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'BackColor' ) 
			__MVPUT( Name + 'BackColor' , 'Nil' )
			__MVPUBLIC ( Name + 'FontColor' ) 
			__MVPUT( Name + 'FontColor' , 'Nil' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'Transparent' ) 
			__MVPUT( Name + 'Transparent' , '.F.' )
			__MVPUBLIC ( Name + 'Action' ) 
			__MVPUT( Name + 'Action' , 'Nil' )
			__MVPUBLIC ( Name + 'AutoSize' ) 
			__MVPUT( Name + 'AutoSize' , '.F.' )
			__MVPUBLIC ( Name + 'Alignment' ) 
			__MVPUT( Name + 'Alignment' , 'LEFT' )

		ElseIf	HMG_UPPER (Line) = 'DEFINE BROWSE'
			ControlType := 'BROWSE'
			Name := HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(8) + Line + CRLF

			else

				DEFINE BROWSE &Name
				PARENT &DesignForm
				HEADERS { Name } 
				WIDTHS { 100 } 
				WORKAREA Test 
				FIELDS { 'Test->Code' } 
				TOOLTIP Name
				ON GOTFOCUS SelectControl (This.Name)
				VSCROLLBAR .F.

			endif

			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , '0' )
			__MVPUBLIC ( Name + 'WorkArea' ) 
			__MVPUT( Name + 'WorkArea' , 'Nil' )
			__MVPUBLIC ( Name + 'Fields' ) 
			__MVPUT( Name + 'Fields' , '{}' )
			__MVPUBLIC ( Name + 'Widths' ) 
			__MVPUT( Name + 'Widths' , '{}' )
			__MVPUBLIC ( Name + 'Headers' ) 
			__MVPUT( Name + 'Headers' , '{}' )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'OnChange' ) 
			__MVPUT( Name + 'OnChange' , 'Nil' )
			__MVPUBLIC ( Name + 'OnGotFocus' ) 
			__MVPUT( Name + 'OnGotFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'OnLostFocus' ) 
			__MVPUT( Name + 'OnLostFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'BackColor' ) 
			__MVPUT( Name + 'BackColor' , 'Nil' )
			__MVPUBLIC ( Name + 'FontColor' ) 
			__MVPUT( Name + 'FontColor' , 'Nil' )
			__MVPUBLIC ( Name + 'OnDblClick' ) 
			__MVPUT( Name + 'OnDblClick' , 'Nil' )
			__MVPUBLIC ( Name + 'AllowEdit' ) 
			__MVPUT( Name + 'AllowEdit' , '.F.' )
			__MVPUBLIC ( Name + 'AllowAppend' ) 
			__MVPUT( Name + 'AllowAppend' , '.F.' )
			__MVPUBLIC ( Name + 'OnHeadClick' ) 
			__MVPUT( Name + 'OnHeadClick' , 'Nil' )
			__MVPUBLIC ( Name + 'AllowDelete' ) 
			__MVPUT( Name + 'AllowDelete' , '.F.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'Image' ) 
			__MVPUT( Name + 'Image' , 'Nil' )
			__MVPUBLIC ( Name + 'Justify' ) 
			__MVPUT( Name + 'Justify' , 'Nil' )
			__MVPUBLIC ( Name + 'Lines' ) 
			__MVPUT( Name + 'Lines' , '.T.' )
			__MVPUBLIC ( Name + 'ReadOnlyFields' ) 
			__MVPUT( Name + 'ReadOnlyFields' , 'Nil' )
			__MVPUBLIC ( Name + 'Valid' ) 
			__MVPUT( Name + 'Valid' , 'Nil' )
			__MVPUBLIC ( Name + 'ValidMessages' ) 
			__MVPUT( Name + 'ValidMessages' , 'Nil' )
			__MVPUBLIC ( Name + 'Lock' ) 
			__MVPUT( Name + 'Lock' , 'Nil' )
			__MVPUBLIC ( Name + 'vScrollBar' ) 
			__MVPUT( Name + 'vScrollBar' , '.T.' )
			__MVPUBLIC ( Name + 'DynamicBackColor' ) 
			__MVPUT( Name + 'DynamicBackColor' , 'Nil' )
			__MVPUBLIC ( Name + 'DynamicForeColor' ) 
			__MVPUT( Name + 'DynamicForeColor' , 'Nil' )
			__MVPUBLIC ( Name + 'InputMask' ) 
			__MVPUT( Name + 'InputMask' , 'Nil' )
			__MVPUBLIC ( Name + 'Format' ) 
			__MVPUT( Name + 'Format' , 'Nil' )
			__MVPUBLIC ( Name + 'When' ) 
			__MVPUT( Name + 'When' , 'Nil' )
			__MVPUBLIC ( Name + 'Break' ) 
			__MVPUT( Name + 'Break' , '.F.' )

			__MVPUBLIC ( Name + 'InputItems' ) 
			__MVPUT( Name + 'InputItems' , 'Nil' )

			__MVPUBLIC ( Name + 'DisplayItems' ) 
			__MVPUT( Name + 'DisplayItems' , 'Nil' )

			__MVPUBLIC ( Name + 'HeaderImages' ) 
			__MVPUT( Name + 'HeaderImages' , 'Nil' )


		ElseIf	HMG_UPPER (Line) = 'DEFINE RADIOGROUP'
			ControlType := 'RADIOGROUP'
			Name := HB_USUBSTR ( Line , 19 , HMG_LEN (Line) - 18 )
			CurrentOptions := "{ 'Option 1','Option 2'}"

			CurrentFontBold		:= '.F.'
			CurrentFontItalic	:= '.F.'
			CurrentFontUnderLine	:= '.F.'
			CurrentFontStrikeout	:= '.F.'
			CurrentHorizontal	:= '.F.'

			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , '0' )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'OnChange' ) 
			__MVPUT( Name + 'OnChange' , 'Nil' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'BackColor' ) 
			__MVPUT( Name + 'BackColor' , 'Nil' )
			__MVPUBLIC ( Name + 'FontColor' ) 
			__MVPUT( Name + 'FontColor' , 'Nil' )
			__MVPUBLIC ( Name + 'TabStop' ) 
			__MVPUT( Name + 'TabStop' , '.T.' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'Transparent' ) 
			__MVPUT( Name + 'Transparent' , '.F.' )
			__MVPUBLIC ( Name + 'Spacing' ) 
			__MVPUT( Name + 'Spacing' , '25' )

			__MVPUBLIC ( Name + 'ReadOnly' ) 
			__MVPUT( Name + 'ReadOnly' , 'Nil' )

			__MVPUBLIC ( Name + 'Orientation' ) 
			__MVPUT( Name + 'Orientation' , 'VERTICAL' )

		ElseIf	HMG_UPPER (Line) = 'DEFINE FRAME'
			ControlType := 'FRAME'
			Name := HB_USUBSTR ( Line , 14 , HMG_LEN (Line) - 13 )
			DEFINE FRAME &Name
			PARENT &DesignForm

			__MVPUBLIC ( Name + 'Caption' ) 
			__MVPUT( Name + 'Caption' , "" )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'Transparent' ) 
			__MVPUT( Name + 'Transparent' , '.F.' )
			__MVPUBLIC ( Name + 'BackColor' ) 
			__MVPUT( Name + 'BackColor' , 'Nil' )
			__MVPUBLIC ( Name + 'FontColor' ) 
			__MVPUT( Name + 'FontColor' , 'Nil' )

		ElseIf	HMG_UPPER (Line) = 'DEFINE TAB'
			TabPageCount := 0
			ControlType := 'TAB'

			* Determine Name
		
			Name := ''
			Started := .F.

			For z := 12 To HMG_LEN ( Line )
				char := HB_USUBSTR ( Line , z , 1 )
				if char == ' ' 
					if Started
						Exit
					EndIf
				Else
					if ! Started
						Started := .T.
					EndIf
					Name := Name + Char
				EndIf           	
			Next z

			* Determine Row & Col

			a := HB_UAT ( " AT " , HMG_UPPER (Line) )
			c := HB_UAT ( "," , HMG_UPPER (Line) )
			Row := HB_USUBSTR ( Line , a + 4 , c - a - 4 )
			Col := ''			
			Started := .F.

			For z := c + 1 To HMG_LEN ( Line )
				char := HB_USUBSTR ( Line , z , 1 )
				if char == ' ' 
					if Started
						Exit
					EndIf
				Else
					if ! Started
						Started := .T.
					EndIf
					Col := Col + Char
				EndIf
			Next z

			* Determine Width
		
			a := HB_UAT ( " WIDTH " , HMG_UPPER (Line) )

			if a > 0

				Width := ''
				Started := .F.

				For z := a + 6 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == ' ' 
						if Started
							Exit
						EndIf
					Else
						if ! Started
							Started := .T.
						EndIf
						Width := Width + Char
					EndIf
				Next z

			EndIf

			* Determine Height
		
			a := HB_UAT ( " HEIGHT " , HMG_UPPER (Line) )

			if a > 0
			
				Height := ''
				Started := .F.

				For z := a + 7 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == ' ' 
						if Started
							Exit
						EndIf
					Else
						if ! Started
							Started := .T.
						EndIf
						Height := Height + Char
					EndIf           	
				Next z

			endif

			* Determine Value
		
			a := HB_UAT ( " VALUE " , HMG_UPPER (Line) )

			Value := ''

			if a > 0
			
				Started := .F.

				For z := a + 6 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == ' ' 
						if Started
							Exit
						EndIf
					Else
						if ! Started
							Started := .T.
						EndIf
						Value := Value + Char
					EndIf           	
				Next z

			endif

			* Determine FontName
		
			a := HB_UAT ( ' FONT "' , HMG_UPPER (Line) )

			FontName := ''

			if a > 0
			
				Started := .F.

				For z := a + 7 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == '"' 
						if Started
							Exit
						EndIf
					Else
						if ! Started
							Started := .T.
						EndIf
						FontName := FontName + Char
					EndIf           	
				Next z

			endif

			Fontname := ALLTRIM ( FontName )

			if Empty ( FontName )
				FontName := 'Arial'
			EndIf

			* Determine FontSize
		
			a := HB_UAT ( " SIZE " , HMG_UPPER (Line) )

			FontSize := ''

			if a > 0
			
				Started := .F.

				For z := a + 5 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == ' ' 
						if Started
							Exit
						EndIf
					Else
						if ! Started
							Started := .T.
						EndIf
						FontSize := FontSize + Char
					EndIf           	
				Next z

			endif

			FontSize := ALLTRIM ( FontSize )

			if Empty ( FontSize )
				FontSize := '9'
			EndIf

			* Determine ToolTip
		
			a := HB_UAT ( " TOOLTIP " , HMG_UPPER (Line) )

			ToolTip := ''

			if a > 0

				Started := .F.

				For z := a + 9 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == '"' 
						if Started
							Exit
						Else
							Started := .T.
						EndIf
					Else
						if Started
							ToolTip := ToolTip + Char
						EndIf
					EndIf
				Next z

			EndIf

			ToolTip := ALLTRIM(ToolTip)

			if	HB_ULEFT ( ToolTip , 1 ) == '"' ;
				.or. ;
				HB_ULEFT ( ToolTip , 1 ) == "'" 

				ToolTip := HB_URIGHT ( ToolTip , HMG_LEN( ToolTip ) - 1 )

			EndIf

			if	HB_URIGHT ( ToolTip, 1 ) == '"' ;
				.or. ;
				HB_URIGHT ( ToolTip , 1 ) == "'"

				ToolTip := HB_ULEFT ( ToolTip , HMG_LEN( ToolTip ) - 1 )

			EndIf

			ToolTip := ALLTRIM(ToolTip)


			* Determine OnChange
		
			a := HB_UAT ( " ON CHANGE " , HMG_UPPER (Line) )

			OnChange := ''

			if a > 0

				Started := .F.

				For z := a + 11 To HMG_LEN ( Line )

					NextToken := HB_USUBSTR ( Line , z , 9 )

					if NextToken == 'NOTABSTOP'
						Exit
					endif

					if NextToken == 'MULTILINE'
						Exit
					endif

					char := HB_USUBSTR ( Line , z , 1 )

					OnChange := OnChange + Char

				Next z

				OnChange := ALLTRIM(OnChange)

				if Empty (OnChange)
					OnChange := 'Nil'
				EndIf
        
			EndIf

			__MVPUBLIC( Name + 'FontName' )
			__MVPUBLIC( Name + 'FontSize' )
			__MVPUT( Name + 'FontName' , FontName )
			__MVPUT( Name + 'FontSize' ,  FontSize )
			__MVPUBLIC( Name + 'ToolTip' )
			__MVPUT( Name + 'ToolTip' , ToolTip )
			__MVPUBLIC( Name + 'OnChange' )
			__MVPUT( Name + 'OnChange' , OnChange )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUBLIC ( Name + 'Buttons' ) 
			__MVPUBLIC ( Name + 'Flat' ) 
			__MVPUBLIC ( Name + 'HotTrack' ) 
			__MVPUBLIC ( Name + 'Vertical' ) 
			__MVPUBLIC ( Name + 'TabStop' ) 
			__MVPUBLIC ( Name + 'Multiline' ) 

			CurrentTabName := Name

			DEFINE TAB &Name OF &DesignForm AT VAL (Row) , VAL (Col) WIDTH VAL ( Width ) HEIGHT VAL ( Height ) ;
				FONT Fontname SIZE VAL(FontSize) ;
				ON CHANGE ( SelectControl (This.Name) , SelectControl (This.Name) )

			* Determine MultiLine
			a := HB_UAT ( " MULTILINE" , HMG_UPPER (Line) )
			if a > 0
				__MVPUT( Name + 'Multiline' , '.T.' )
			else
				__MVPUT( Name + 'Multiline' , '.F.' )
			endif

			* Determine TabStop
			a := HB_UAT ( " NOTABSTOP" , HMG_UPPER (Line) )
			if a > 0
				__MVPUT( Name + 'TabStop' , '.F.' )
			else
				__MVPUT( Name + 'TabStop' , '.T.' )
			endif

			* Determine Vertical
			a := HB_UAT ( " VERTICAL" , HMG_UPPER (Line) )
			if a > 0
				__MVPUT( Name + 'Vertical' , '.T.' )
				_HMG_SYSDATA [ 269 ]	:= .T.
			else
				__MVPUT( Name + 'Vertical' , '.F.' )
			endif

			* Determine HotTrack
			a := HB_UAT ( " HOTTRACK" , HMG_UPPER (Line) )
			if a > 0
				__MVPUT( Name + 'HotTrack' , '.T.' )
				_HMG_SYSDATA [ 268 ]	:= .T.
			else
				__MVPUT( Name + 'HotTrack' , '.F.' )
			endif

			* Determine Buttons
			a := HB_UAT ( " BUTTONS" , HMG_UPPER (Line) )
			if a > 0
				__MVPUT( Name + 'Buttons' , '.T.' )
				_HMG_SYSDATA [ 266 ]	:= .T.
			else
				__MVPUT( Name + 'Buttons' , '.F.' )
			endif

			* Determine Flat
			a := HB_UAT ( " FLAT" , HMG_UPPER (Line) )
			if a > 0
				__MVPUT( Name + 'Flat' , '.T.' )
				_HMG_SYSDATA [ 267 ]	:= .T.
			else
				__MVPUT( Name + 'Flat' , '.F.' )
			endif


			* Determine Bold
			a := HB_UAT ( " BOLD" , HMG_UPPER (Line) )
			if a > 0
				__MVPUT( Name + 'FontBold' , '.T.' )
				_HMG_SYSDATA [ 301 ]	:= .T.
			else
				__MVPUT( Name + 'FontBold' , '.F.' )
			endif
			* Determine Italic
			a := HB_UAT ( " ITALIC" , HMG_UPPER (Line) )
			if a > 0
				_HMG_SYSDATA [ 302 ]	:= .T.
				__MVPUT( Name + 'FontItalic' , '.T.' )
			else
				__MVPUT( Name + 'FontItalic' , '.F.' )
			endif
			* Determine UnderLine
			a := HB_UAT ( " UNDERLINE" , HMG_UPPER (Line) )
			if a > 0
				_HMG_SYSDATA [ 303 ]	:= .T.
				__MVPUT( Name + 'FontUnderLine' , '.T.' )
			else
				__MVPUT( Name + 'FontUnderLine' , '.F.' )
			endif
			* Determine StrikeOut
			a := HB_UAT ( " STRIKEOUT" , HMG_UPPER (Line) )
			if a > 0
				_HMG_SYSDATA [ 304 ]	:= .T.
				__MVPUT( Name + 'FontStrikeOut' , '.T.' )
			else
				__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			endif


			CurrentCaptions :=  '{ '
			CurrentPageImages := '{ '

			if empty(value)
				value := '0'
			endif

			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , Value )
			__MVPUBLIC ( Name + 'Captions' ) 
			__MVPUBLIC ( Name + 'PageCount' ) 
			__MVPUT( Name + 'PageCount' , '0' )
			__MVPUT( Name + 'Captions' ,  "{'',''}" )

		ElseIf	HMG_UPPER (Line) = 'PAGE '
			TabPageCount ++

			* Get Image

			x := HB_UTF8RAT ( ' IMAGE ' , HMG_UPPER(Line) )

			if x > 0 .and. !IsLiteral ( Line , x )
				CurrentImage := HB_USUBSTR ( Line , x + 7 , 255 )
				Line := HB_ULEFT ( Line , x )
			Else															
				CurrentImage := ''
			EndIf

			if	HB_ULEFT ( CurrentImage , 1 ) == '"' ;
				.or. ;
				HB_ULEFT ( CurrentImage , 1 ) == "'" 

				CurrentImage := HB_URIGHT (CurrentImage , HMG_LEN(CurrentImage) - 1 )

			EndIf

			if	HB_URIGHT ( CurrentImage , 1 ) == '"' ;
				.or. ;
				HB_URIGHT ( CurrentImage , 1 ) == "'"

				CurrentImage := HB_ULEFT (CurrentImage , HMG_LEN(CurrentImage) - 1 )

			EndIf

			CurrentPageImages :=  CurrentpageImages + chr(34) + CurrentImage + chr(34) + " , "


			CurrentCaption := ALLTRIM ( HB_URIGHT ( Line , HMG_LEN (Line) - 5 ) )

			if	HB_ULEFT ( CurrentCaption , 1 ) == '"' ;
				.or. ;
				HB_ULEFT ( CurrentCaption , 1 ) == "'" 

				CurrentCaption := HB_URIGHT (CurrentCaption , HMG_LEN(CurrentCaption) - 1 )

			EndIf

			if	HB_URIGHT ( CurrentCaption , 1 ) == '"' ;
				.or. ;
				HB_URIGHT ( CurrentCaption , 1 ) == "'"

				CurrentCaption := HB_ULEFT (CurrentCaption , HMG_LEN(CurrentCaption) - 1 )

			EndIf

			DEFINE PAGE CurrentCaption

			CurrentCaptions :=  CurrentCaptions + chr(34) + CurrentCaption + chr(34) + " , "

		ElseIf	HMG_UPPER (Line) = 'END PAGE'
			END PAGE 

		ElseIf	HMG_UPPER (Line) = 'END TAB'

			END TAB

			CurrentCaptions :=  ALLTRIM(CurrentCaptions)
			CurrentCaptions := HB_ULEFT ( CurrentCaptions , HMG_LEN(CurrentCaptions) - 1 )
			CurrentCaptions :=  CurrentCaptions + ' }' 

			CurrentPageImages :=  ALLTRIM(CurrentPageImages)
			CurrentPageImages := HB_ULEFT ( CurrentpageImages , HMG_LEN(CurrentPageImages) - 1 )
			CurrentpageImages :=  CurrentPageImages + ' }' 

			__MVPUT( CurrentTabName + 'PageCount' , ALLTRIM(STR(TabpageCount)) )
			__MVPUT( CurrentTabName + 'Captions' ,  CurrentCaptions )

			__MVPUBLIC ( CurrentTabName + 'PageImages' ) 
			__MVPUT( CurrentTabName + 'PageImages' ,  CurrentPageImages )


		ElseIf	HMG_UPPER (Line) = 'DEFINE ANIMATEBOX'
			ControlType := 'ANIMATEBOX'
			Name := HB_USUBSTR ( Line , 19 , HMG_LEN (Line) - 18 )
			DEFINE ANIMATEBOX &Name
			PARENT &DesignForm
			FILE ''
			CENTER .T.
			AUTOPLAY .T.

			__MVPUBLIC ( Name + 'File' ) 
			__MVPUT( Name + 'File' , "" )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'Transparent' ) 
			__MVPUT( Name + 'Transparent' , '.F.' )
			__MVPUBLIC ( Name + 'AutoPlay' ) 
			__MVPUT( Name + 'AutoPlay' , '.F.' )
			__MVPUBLIC ( Name + 'Center' ) 
			__MVPUT( Name + 'Center' , '.F.' )

		ElseIf	HMG_UPPER (Line) = 'DEFINE HYPERLINK'
			ControlType := 'HYPERLINK'
			Name := HB_USUBSTR ( Line , 18 , HMG_LEN (Line) - 17 )
			DEFINE HYPERLINK &Name
			PARENT &DesignForm
			ADDRESS _HLK

			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , '' )
			__MVPUBLIC ( Name + 'Address' ) 
			__MVPUT( Name + 'Address' , '' )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'AutoSize' ) 
			__MVPUT( Name + 'AutoSize' , '.F.' )
			__MVPUBLIC ( Name + 'BackColor' ) 
			__MVPUT( Name + 'BackColor' , 'Nil' )
			__MVPUBLIC ( Name + 'FontColor' ) 
			__MVPUT( Name + 'FontColor' , 'Nil' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'HandCursor' ) 
			__MVPUT( Name + 'HandCursor' , '.F.' )

		ElseIf	HMG_UPPER (Line) = 'DEFINE MONTHCALENDAR'
			ControlType := 'MONTHCALENDAR'
			Name := HB_USUBSTR ( Line , 22 , HMG_LEN (Line) - 21 )
			DEFINE MONTHCALENDAR &Name
			PARENT &DesignForm
			ON CHANGE SelectControl (This.Name)

			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , 'CTOD(  /  /  )' )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'OnChange' ) 
			__MVPUT( Name + 'OnChange' , 'Nil' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'Today' ) 
			__MVPUT( Name + 'Today' , '.T.' )
			__MVPUBLIC ( Name + 'TodayCircle' ) 
			__MVPUT( Name + 'TodayCircle' , '.T.' )
			__MVPUBLIC ( Name + 'WeekNumbers' ) 
			__MVPUT( Name + 'WeekNumbers' , '.F.' )
			__MVPUBLIC ( Name + 'TabStop' ) 
			__MVPUT( Name + 'TabStop' , '.T.' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )

		ElseIf	HMG_UPPER (Line) = 'DEFINE RICHEDITBOX'
			ControlType := 'RICHEDITBOX'
			Name := HB_USUBSTR ( Line , 20 , HMG_LEN (Line) - 19 )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(8) + Line + CRLF

			else

				DEFINE RICHEDITBOX &Name
				PARENT &DesignForm
				ON GOTFOCUS SelectControl (This.Name)
				VALUE Name

			endif

			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , '' )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'OnChange' ) 
			__MVPUT( Name + 'OnChange' , 'Nil' )
			__MVPUBLIC ( Name + 'OnGotFocus' ) 
			__MVPUT( Name + 'OnGotFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'OnLostFocus' ) 
			__MVPUT( Name + 'OnLostFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'TabStop' ) 
			__MVPUT( Name + 'TabStop' , '.T.' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'BackColor' ) 
			__MVPUT( Name + 'BackColor' , 'Nil' )
			__MVPUBLIC ( Name + 'MaxLength' ) 
			__MVPUT( Name + 'MaxLength' , 'Nil' )
			__MVPUBLIC ( Name + 'Field' ) 
			__MVPUT( Name + 'Field' , 'Nil' )
			__MVPUBLIC ( Name + 'ReadOnly' ) 
			__MVPUT( Name + 'ReadOnly' , '.F.' )
			__MVPUBLIC ( Name + 'Break' ) 
			__MVPUT( Name + 'Break' , '.F.' )


		ElseIf	HMG_UPPER (Line) = 'DEFINE ACTIVEX'
			ControlType := 'ACTIVEX'
			Name := HB_USUBSTR ( Line , 16 , HMG_LEN (Line) - 15 )

			__MVPUBLIC ( Name + 'ProgId' ) 
			__MVPUT( Name + 'ProgId' , '' )



		ElseIf	HMG_UPPER (Line) = 'DEFINE PROGRESSBAR'
			ControlType := 'PROGRESSBAR'
			Name := HB_USUBSTR ( Line , 20 , HMG_LEN (Line) - 19 )

			__MVPUBLIC ( Name + 'RangeMax' ) 
			__MVPUT( Name + 'RangeMax' , '1' )
			__MVPUBLIC ( Name + 'RangeMin' ) 
			__MVPUT( Name + 'RangeMin' , '10' )
			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , '0' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'BackColor' ) 
			__MVPUT( Name + 'BackColor' , 'Nil' )
			__MVPUBLIC ( Name + 'ForeColor' ) 
			__MVPUT( Name + 'ForeColor' , 'Nil' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )
			__MVPUBLIC ( Name + 'Smooth' ) 
			__MVPUT( Name + 'Smooth' , '.F.' )
			__MVPUBLIC ( Name + 'Orientation' ) 
			__MVPUT( Name + 'Orientation' , 'HORIZONTAL' )

		ElseIf	HMG_UPPER (Line) = 'DEFINE PLAYER'
			ControlType := 'PLAYER'
			Name := HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 )

			__MVPUBLIC ( Name + 'File' ) 
			__MVPUT( Name + 'File' , "" )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )

			__MVPUBLIC ( Name + 'AutoSizeWindow' ) 
			__MVPUT( Name + 'AutoSizeWindow' , '.T.' )

			__MVPUBLIC ( Name + 'AutoSizeMovie' ) 
			__MVPUT( Name + 'AutoSizeMovie' , '.T.' )

			__MVPUBLIC ( Name + 'ErrorDlg' ) 
			__MVPUT( Name + 'ErrorDlg' , '.T.' )

			__MVPUBLIC ( Name + 'Menu' ) 
			__MVPUT( Name + 'Menu' , '.T.' )

			__MVPUBLIC ( Name + 'Open' ) 
			__MVPUT( Name + 'Open' , '.T.' )

			__MVPUBLIC ( Name + 'PlayBar' ) 
			__MVPUT( Name + 'PlayBar' , '.T.' )

			__MVPUBLIC ( Name + 'ShowAll' ) 
			__MVPUT( Name + 'ShowAll' , '.F.' )

			__MVPUBLIC ( Name + 'ShowMode' ) 
			__MVPUT( Name + 'ShowMode' , '.F.' )

			__MVPUBLIC ( Name + 'ShowName' ) 
			__MVPUT( Name + 'ShowName' , '.F.' )

			__MVPUBLIC ( Name + 'ShowPosition' ) 
			__MVPUT( Name + 'ShowPosition' , '.F.' )


		ElseIf	HMG_UPPER (Line) = 'DEFINE IPADDRESS'
			ControlType := 'IPADDRESS'
			Name := HB_USUBSTR ( Line , 18 , HMG_LEN (Line) - 17 )

			CurrentFontBold		:= '.F.'
			CurrentFontItalic	:= '.F.'
			CurrentFontUnderLine	:= '.F.'
			CurrentFontStrikeout	:= '.F.'

			__MVPUBLIC ( Name + 'Value' ) 
			__MVPUT( Name + 'Value' , '{ 0 , 0 , 0 , 0 }' )
			__MVPUBLIC ( Name + 'FontName' ) 
			__MVPUT( Name + 'FontName' , 'Arial' )
			__MVPUBLIC ( Name + 'FontSize' ) 
			__MVPUT( Name + 'FontSize' , '9' )
			__MVPUBLIC ( Name + 'ToolTip' ) 
			__MVPUT( Name + 'ToolTip' , '' )
			__MVPUBLIC ( Name + 'OnChange' ) 
			__MVPUT( Name + 'OnChange' , 'Nil' )
			__MVPUBLIC ( Name + 'OnGotFocus' ) 
			__MVPUT( Name + 'OnGotFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'OnLostFocus' ) 
			__MVPUT( Name + 'OnLostFocus' , 'Nil' )
			__MVPUBLIC ( Name + 'FontBold' ) 
			__MVPUT( Name + 'FontBold' , '.F.' )
			__MVPUBLIC ( Name + 'FontItalic' ) 
			__MVPUT( Name + 'FontItalic' , '.F.' )
			__MVPUBLIC ( Name + 'FontStrikeOut' ) 
			__MVPUT( Name + 'FontStrikeOut' , '.F.' )
			__MVPUBLIC ( Name + 'FontUnderLine' ) 
			__MVPUT( Name + 'FontUnderLine' , '.F.' )
			__MVPUBLIC ( Name + 'TabStop' ) 
			__MVPUT( Name + 'TabStop' , '.T.' )
			__MVPUBLIC ( Name + 'Visible' ) 
			__MVPUT( Name + 'Visible' , '.T.' )
			__MVPUBLIC ( Name + 'HelpId' ) 
			__MVPUT( Name + 'HelpId' , 'Nil' )

		ElseIf	HMG_UPPER (Line) = 'DEFINE TIMER'
			ControlType := 'TIMER'

			* Determine Name
		
			Name := ''
			Started := .F.

			For z := 14 To HMG_LEN ( Line )
				char := HB_USUBSTR ( Line , z , 1 )
				if char == ' ' 
					if Started
						Exit
					EndIf
				Else
					if ! Started
						Started := .T.
					EndIf
					Name := Name + Char
				EndIf           	
			Next z

			* Determine Interval

			Interval := ''		
			a := HB_UAT ( " INTERVAL " , HMG_UPPER (Line) )

			if a > 0

				Started := .F.

				For z := a + 9 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == ' ' 
						if Started
							Exit
						EndIf
					Else
						if ! Started
							Started := .T.
						EndIf
						Interval := Interval + Char
					EndIf
				Next z

			EndIf

			* Determine Action

			CurrentAction := ''		
			a := HB_UAT ( " ACTION " , HMG_UPPER (Line) )

			if a > 0
				CurrentAction := HB_USUBSTR ( Line , a + 7 , HMG_LEN (Line) - ( a + 6 ) )
			Else
				CurrentAction := ''
			EndIf

			DEFINE BUTTON &Name
				PARENT &DesignForm
				ROW GetProperty ( DesignForm , 'Height' ) - 45 - GetTitleHeight()
				COL 10 + (TimersLoaded * 40)
				WIDTH 30 
				HEIGHT 30 
				ACTION SelectControl (This.name)
				PICTURE 'timer'
				FLAT .T.
			END BUTTON

			_HMG_SYSDATA [ 39 ] [ GetControlIndex ( Name , DesignForm ) ] := 5

			TimersLoaded++

			if empty ( interval )
				interval := '0'
			endif
			if empty ( Currentaction )
				Currentaction := 'Nil'
			endif

			__MVPUBLIC ( Name + 'Interval' ) 
			__MVPUT( Name + 'Interval' , Interval )
			__MVPUBLIC ( Name + 'Action' ) 
			__MVPUT( Name + 'Action' , Currentaction )


*******************************************************************************





*******************************************************************************

		// END COMMAND

		ElseIf	HMG_UPPER (Line) = 'END BUTTON'
			END BUTTON
		ElseIf	HMG_UPPER (Line) = 'END CHECKBOX'
			END CHECKBOX
		ElseIf	HMG_UPPER (Line) = 'END LISTBOX'

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(8) + Line + CRLF

			else

				END LISTBOX

			endif

		ElseIf	HMG_UPPER (Line) = 'END COMBOBOX'

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(8) + Line + CRLF

			else

				END COMBOBOX

			endif

		ElseIf	HMG_UPPER (Line) = 'END CHECKBUTTON'
			END CHECKBUTTON
			_HMG_SYSDATA [ 39 ] [ GetControlIndex ( Name , DesignForm ) ] := 1
		ElseIf	HMG_UPPER (Line) = 'END GRID'

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(8) + Line + CRLF

			else

				if ALLTRIM(HMG_UPPER(  __MVGET ( Name + 'ShowHeaders' )  )) == '.T.'
					SHOWHEADERS .T.
				else
					SHOWHEADERS .F.
				endif

				END GRID

			endif

		ElseIf	HMG_UPPER (Line) = 'END SLIDER'
			END SLIDER
			if __MVGET ( name + 'Orientation' ) == 'VERTICAL' ;
				.and. ;
				__MVGET ( name + 'TickMarks' ) == 'BOTTOM' 
			
				__MVPUT ( name + 'TickMarks' , 'RIGHT' )

			endif
		ElseIf	HMG_UPPER (Line) = 'END SPINNER'
			END SPINNER
		ElseIf	HMG_UPPER (Line) = 'END IMAGE'
			END IMAGE
		ElseIf	HMG_UPPER (Line) = 'END TREE'

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(8) + Line + CRLF

			else

				END TREE

			endif

		ElseIf	HMG_UPPER (Line) = 'END DATEPICKER'
			END DATEPICKER
		ElseIf	HMG_UPPER (Line) = 'END TEXTBOX'
			END TEXTBOX
		ElseIf	HMG_UPPER (Line) = 'END EDITBOX'

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(8) + Line + CRLF

			else

				IF HMG_UPPER ( ALLTRIM( CURRENTHSCROLLBAR ) ) == '.T.'
					HSCROLLBAR .T.
				ELSE
					HSCROLLBAR .F.
				ENDIF

				IF HMG_UPPER ( ALLTRIM( CURRENTVSCROLLBAR ) ) == '.T.'
					VSCROLLBAR .T.
				ELSE
					VSCROLLBAR .F.
				ENDIF

				END EDITBOX

			endif

		ElseIf	HMG_UPPER (Line) = 'END LABEL'
			ACTION SelectControl( This.Name )
			END LABEL
		ElseIf	HMG_UPPER (Line) = 'END BROWSE'

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(8) + Line + CRLF

			else

				END BROWSE

			endif

		ElseIf	HMG_UPPER (Line) = 'END RADIOGROUP'

			aTemp := StringToArray ( CurrentOptions )

			DEFINE RADIOGROUP &Name
				WIDTH CurrentWidth
				ROW CurrentRow
				COL CurrentCol
				PARENT &DesignForm
				OPTIONS aTemp
				ON CHANGE SelectControl (This.Name)
				FONTNAME CurrentFontName
				FONTSIZE CurrentFontSize
				BACKCOLOR &CurrentBackColor
				FONTCOLOR &CurrentFontColor
				SPACING CurrentSpacing

				if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
					FONTBOLD .T.
				else
					FONTBOLD .F.
				endif

				if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
					FONTITALIC .T.
				else
					FONTITALIC .F.
				endif

				if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
					FONTUNDERLINE .T.
				else
					FONTUNDERLINE .F.
				endif

				if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
					FONTSTRIKEOUT .T.
				else
					FONTSTRIKEOUT .F.
				endif

				if ALLTRIM(HMG_UPPER(CurrentHorizontal)) == '.T.'
					HORIZONTAL .T.
				else
					HORIZONTAL .F.
				endif

			END RADIOGROUP

			__MVPUBLIC ( Name + 'Options' ) 
			__MVPUT( Name + 'Options' , CurrentOptions )

		ElseIf	HMG_UPPER (Line) = 'END FRAME'

			if empty ( currentcaption )
				FONTSIZE 1
			endif

			END FRAME
		ElseIf	HMG_UPPER (Line) = 'END ANIMATEBOX'
			END ANIMATEBOX

		ElseIf	HMG_UPPER (Line) = 'END HYPERLINK'
			END HYPERLINK

			w := GetControlIndex ( Name , DesignForm )
			macrovar := 'SelectControl ('+ chr(34) + Name + chr(34) + ')'
			_HMG_SYSDATA [ 6 ] [w] := { || &macrovar } 
			_HMG_SYSDATA [ 39 ] [w] := 6

			RedrawWindow ( GetControlHandle ( Name , DesignForm ) )

		ElseIf	HMG_UPPER (Line) = 'END MONTHCALENDAR'
			END MONTHCALENDAR

		ElseIf	HMG_UPPER (Line) = 'END RICHEDITBOX'

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(8) + Line + CRLF

			else

				END RICHEDITBOX

			endif

		ElseIf	HMG_UPPER (Line) = 'END PROGRESSBAR'

			@ CurrentRow , CurrentCol LABEL &Name ;
				OF &DesignForm ;
				VALUE Name ACTION SelectControl (This.Name) ;
				WIDTH if ( CurrentWidth == -1 , 120 , CurrentWidth ) ;
				HEIGHT if ( CurrentHeight == -1 , 25 , CurrentHeight ) ;
				BORDER ;
				BACKCOLOR &CurrentBackColor ;
				FONTCOLOR &CurrentFontColor 

			w := GetControlIndex ( Name , DesignForm )
			_HMG_SYSDATA [ 39 ] [w] := 2

			CurrentWidth	:= -1
			CurrentHeight	:= -1

		ElseIf	HMG_UPPER (Line) = 'END PLAYER'

			@ CurrentRow , CurrentCol LABEL &Name ;
				OF &DesignForm ;
				VALUE Name ACTION SelectControl (This.Name) ;
				WIDTH if ( CurrentWidth == -1 , 120 , CurrentWidth ) HEIGHT if ( CurrentHeight == -1 , 120 , CurrentHeight ) ;
				BORDER

			w := GetControlIndex ( Name , DesignForm )
			_HMG_SYSDATA [ 39 ] [w] := 3

			CurrentWidth	:= -1
			CurrentHeight	:= -1

		ElseIf	HMG_UPPER (Line) = 'END ACTIVEX'

			@ CurrentRow , CurrentCol LABEL &Name ;
				OF &DesignForm ;
				VALUE Name ACTION SelectControl (This.Name) ;
				WIDTH if ( CurrentWidth == -1 , 120 , CurrentWidth ) HEIGHT if ( CurrentHeight == -1 , 120 , CurrentHeight ) ;
				BORDER

			w := GetControlIndex ( Name , DesignForm )
			_HMG_SYSDATA [ 39 ] [w] := 7

			CurrentWidth	:= -1
			CurrentHeight	:= -1


		ElseIf	HMG_UPPER (Line) = 'END IPADDRESS'

			@ CurrentRow , CurrentCol LABEL &Name ;
				OF &DesignForm ;
				VALUE Name ACTION SelectControl (This.Name) ;
				WIDTH if ( CurrentWidth == -1 , 120 , CurrentWidth ) HEIGHT if ( CurrentHeight == -1 , 24 , CurrentHeight ) ;
				BORDER

			w := GetControlIndex ( Name , DesignForm )
			_HMG_SYSDATA [ 39 ] [w] := 4

			SetProperty ( DesignForm , Name , 'FontName' , CurrentFontName )
			SetProperty ( DesignForm , Name , 'FontSize' , VAL ( CurrentFontSize ) )

			SetProperty ( DesignForm , Name , 'FontBold' , if ( ALLTRIM(HMG_UPPER(CurrentFontBold )) == '.T.' , .T. , .F. ) )
			SetProperty ( DesignForm , Name , 'FontItalic' , if ( ALLTRIM(HMG_UPPER(CurrentFontItalic )) == '.T.' , .T. , .F. ) )
			SetProperty ( DesignForm , Name , 'FontUnderLine' , if ( ALLTRIM(HMG_UPPER(CurrentFontUnderLine )) == '.T.' , .T. , .F. ) )
			SetProperty ( DesignForm , Name , 'FontStrikeout' , if ( ALLTRIM(HMG_UPPER(CurrentFontStrikeout )) == '.T.' , .T. , .F. ) )

			CurrentWidth	:= -1
			CurrentHeight	:= -1



		///////////////////////////////////////////////////////////////
		// ROWSOURCE PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ROWSOURCE'

			CurrentRowSource := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ROWSOURCE ' + CurrentRowSource + CRLF

				__MVPUT( Name + 'ROWSOURCE' , CurrentRowSource )

			else

				__MVPUT( Name + 'ROWSOURCE' , CurrentRowSource )

			endif

		///////////////////////////////////////////////////////////////
		// COLUMNFIELDS PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'COLUMNFIELDS'

			CurrentColumnFields := ALLTRIM(HB_USUBSTR ( Line , 14 , HMG_LEN (Line) - 13 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'COLUMNFIELDS ' + CurrentColumnFields + CRLF

				__MVPUT( Name + 'COLUMNFIELDS' , CurrentColumnFields )

			else

				__MVPUT( Name + 'COLUMNFIELDS' , CurrentColumnFields )

			endif

		///////////////////////////////////////////////////////////////
		// ALLOWAPPEND PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ALLOWAPPEND'

			CurrentAllowAppend := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ALLOWAPPEND ' + CurrentAllowAppend + CRLF

				__MVPUT( Name + 'ALLOWAPPEND' , CurrentAllowAppend )

			else

				__MVPUT( Name + 'ALLOWAPPEND' , CurrentAllowAppend )

			endif

		///////////////////////////////////////////////////////////////
		// ALLOWDELETE PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ALLOWDELETE'

			CurrentAllowDelete := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ALLOWDELETE ' + CurrentAllowDelete + CRLF

				__MVPUT( Name + 'ALLOWDELETE' , CurrentAllowDelete )

			else

				__MVPUT( Name + 'ALLOWDELETE' , CurrentAllowDelete )

			endif


		///////////////////////////////////////////////////////////////
		// BUFFERED PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'BUFFERED'

			CurrentBuffered := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'BUFFERED ' + CurrentBuffered + CRLF

				__MVPUT( Name + 'BUFFERED' , CurrentBuffered )

			else

				__MVPUT( Name + 'BUFFERED' , CurrentBuffered )

			endif

		///////////////////////////////////////////////////////////////
		// DYNAMICDISPLAY PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'DYNAMICDISPLAY'

			CurrentDynamicDisplay := ALLTRIM(HB_USUBSTR ( Line , 16 , HMG_LEN (Line) - 15 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'DYNAMICDISPLAY ' + CurrentDynamicDisplay + CRLF

				__MVPUT( Name + 'DYNAMICDISPLAY' , CurrentDynamicDisplay )

			else

				__MVPUT( Name + 'DYNAMICDISPLAY' , CurrentDynamicDisplay )

			endif


		///////////////////////////////////////////////////////////////
		// WHEN PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'WHEN'

			CurrentWhen := ALLTRIM(HB_USUBSTR ( Line , 6 , HMG_LEN (Line) - 5 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'WHEN ' + CurrentWhen + CRLF

				__MVPUT( Name + 'WHEN' , CurrentWhen )

			else

				__MVPUT( Name + 'WHEN' , CurrentWhen )

			endif

		///////////////////////////////////////////////////////////////
		// DYNAMICBACKCOLOR PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'DYNAMICBACKCOLOR'

			CurrentDynamicBackColor := ALLTRIM(HB_USUBSTR ( Line , 18 , HMG_LEN (Line) - 17 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'DYNAMICBACKCOLOR ' + CurrentDynamicBackColor + CRLF

				__MVPUT( Name + 'DYNAMICBACKCOLOR' , CurrentDynamicBackColor )

			else

				__MVPUT( Name + 'DYNAMICBACKCOLOR' , CurrentDynamicBackColor )

			endif

		///////////////////////////////////////////////////////////////
		// DYNAMICFORECOLOR PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'DYNAMICFORECOLOR'

			CurrentDynamicForeColor := ALLTRIM(HB_USUBSTR ( Line , 18 , HMG_LEN (Line) - 17 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'DYNAMICFORECOLOR ' + CurrentDynamicForeColor + CRLF

				__MVPUT( Name + 'DYNAMICFORECOLOR' , CurrentDynamicForeColor )

			else

				__MVPUT( Name + 'DYNAMICFORECOLOR' , CurrentDynamicForeColor )

			endif

		///////////////////////////////////////////////////////////////
		// INPUTITEMS PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'INPUTITEMS'

			CurrentInputItems := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'INPUTITEMS ' + CurrentInputItems + CRLF

				__MVPUT( Name + 'INPUTITEMS' , CurrentInputItems )

			else

				__MVPUT( Name + 'INPUTITEMS' , CurrentInputItems )

			endif

		///////////////////////////////////////////////////////////////
		// DISPLAYITEMS PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'DISPLAYITEMS'

			CurrentDisplayItems := ALLTRIM(HB_USUBSTR ( Line , 14 , HMG_LEN (Line) - 13 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'DISPLAYITEMS ' + CurrentDisplayItems + CRLF

				__MVPUT( Name + 'DISPLAYITEMS' , CurrentDisplayItems )

			else

				__MVPUT( Name + 'DISPLAYITEMS' , CurrentDisplayItems )

			endif

		///////////////////////////////////////////////////////////////
		// COLUMNWHEN PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'COLUMNWHEN'

			CurrentColumnWhen := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'COLUMNWHEN ' + CurrentColumnWhen + CRLF

				__MVPUT( Name + 'COLUMNWHEN' , CurrentColumnWhen )

			else

				__MVPUT( Name + 'COLUMNWHEN' , CurrentColumnWhen )

			endif

		///////////////////////////////////////////////////////////////
		// COLUMNVALID PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'COLUMNVALID'

			CurrentColumnValid := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'COLUMNVALID ' + CurrentColumnValid + CRLF

				__MVPUT( Name + 'COLUMNVALID' , CurrentColumnValid )

			else

				__MVPUT( Name + 'COLUMNVALID' , CurrentColumnValid )

			endif

		///////////////////////////////////////////////////////////////
		// COLUMNCONTROLS PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'COLUMNCONTROLS'

			CurrentColumnControls := ALLTRIM(HB_USUBSTR ( Line , 16 , HMG_LEN (Line) - 15 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'COLUMNCONTROLS ' + CurrentColumnControls + CRLF

				__MVPUT( Name + 'COLUMNCONTROLS' , CurrentColumnControls )

			else

				__MVPUT( Name + 'COLUMNCONTROLS' , CurrentColumnControls )

			endif

		///////////////////////////////////////////////////////////////
		// TODAY PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'NOTODAY '

			CurrentToday := HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) 

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'NOTODAY ' + CurrentToday + CRLF

				if ALLTRIM(HMG_UPPER(CurrentToday)) == '.T.'
					__MVPUT( Name + 'Today' , '.F.' )
				else
					__MVPUT( Name + 'Today' , '.T.' )
				endif

			else

				if ALLTRIM(HMG_UPPER(CurrentToday)) == '.T.'
					__MVPUT( Name + 'Today' , '.F.' )
					NOTODAY .T.
				else
					__MVPUT( Name + 'Today' , '.T.' )
					NOTODAY .F.
				endif

			endif

		///////////////////////////////////////////////////////////////
		// TODAYCIRCLE PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'NOTODAYCIRCLE'

			CurrentTodayCircle := HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) 

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'NOTODAYCIRCLE ' + CurrentTodayCircle + CRLF

				if ALLTRIM(HMG_UPPER(CurrentTodayCircle)) == '.T.'
					__MVPUT( Name + 'TodayCircle' , '.F.' )
				else
					__MVPUT( Name + 'TodayCircle' , '.T.' )
				endif

			else

				if ALLTRIM(HMG_UPPER(CurrentTodayCircle)) == '.T.'
					__MVPUT( Name + 'TodayCircle' , '.F.' )
					NOTODAYCIRCLE .T.
				else
					__MVPUT( Name + 'TodayCircle' , '.T.' )
					NOTODAYCIRCLE .F.
				endif

			endif

		///////////////////////////////////////////////////////////////
		// WEEKNUMBERS PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'WEEKNUMBERS'

			CurrentWeekNumbers := HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) 

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'WEEKNUMBERS ' + CurrentWeekNumbers + CRLF

				if ALLTRIM(HMG_UPPER(CurrentWeekNumbers)) == '.T.'
					__MVPUT( Name + 'WeekNumbers' , '.T.' )
				else
					__MVPUT( Name + 'WeekNumbers' , '.F.' )
				endif

			else

				if ALLTRIM(HMG_UPPER(CurrentWeekNumbers)) == '.T.'
					__MVPUT( Name + 'WeekNumbers' , '.T.' )
					WEEKNUMBERS .T.
				else
					__MVPUT( Name + 'WeekNumbers' , '.F.' )
					WEEKNUMBERS .F.
				endif

			endif

		///////////////////////////////////////////////////////////////
		// AUTOSIZEWINDOW PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'NOAUTOSIZEWINDOW'

			CurrentMediaProp := HB_USUBSTR ( Line , 18 , HMG_LEN (Line) - 17 ) 

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'NOAUTOSIZEWINDOW ' + CurrentMediaProp + CRLF

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'AutoSizeWindow' , '.F.' )
				else
					__MVPUT( Name + 'AutoSizeWindow' , '.T.' )
				endif

			else

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'AutoSizeWindow' , '.F.' )
				else
					__MVPUT( Name + 'AutoSizeWindow' , '.T.' )
				endif

			endif

		///////////////////////////////////////////////////////////////
		// AUTOSIZEMOVIE PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'NOAUTOSIZEMOVIE'

			CurrentMediaProp := HB_USUBSTR ( Line , 17 , HMG_LEN (Line) - 16 ) 

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'NOAUTOSIZEMOVIE ' + CurrentMediaProp + CRLF

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'AutoSizeMovie' , '.F.' )
				else
					__MVPUT( Name + 'AutoSizeMovie' , '.T.' )
				endif

			else

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'AutoSizeMovie' , '.F.' )
				else
					__MVPUT( Name + 'AutoSizeMovie' , '.T.' )
				endif

			endif

		///////////////////////////////////////////////////////////////
		// ERRORDLG PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'NOERRORDLG'

			CurrentMediaProp := HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) 

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'NOERRORDLG ' + CurrentMediaProp + CRLF

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'ErrorDlg' , '.F.' )
				else
					__MVPUT( Name + 'ErrorDlg' , '.T.' )
				endif

			else

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'ErrorDlg' , '.F.' )
				else
					__MVPUT( Name + 'ErrorDlg' , '.T.' )
				endif

			endif

		///////////////////////////////////////////////////////////////
		// MENU PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'NOMENU'

			CurrentMediaProp := HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) 

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'NOMENU ' + CurrentMediaProp + CRLF

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'Menu' , '.F.' )
				else
					__MVPUT( Name + 'Menu' , '.T.' )
				endif

			else

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'Menu' , '.F.' )
				else
					__MVPUT( Name + 'Menu' , '.T.' )
				endif

			endif

		///////////////////////////////////////////////////////////////
		// OPEN PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'NOOPEN'

			CurrentMediaProp := HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) 

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'NOOPEN ' + CurrentMediaProp + CRLF

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'Open' , '.F.' )
				else
					__MVPUT( Name + 'Open' , '.T.' )
				endif

			else

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'Open' , '.F.' )
				else
					__MVPUT( Name + 'Open' , '.T.' )
				endif

			endif

		///////////////////////////////////////////////////////////////
		// PLAYBAR PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'NOPLAYBAR'

			CurrentMediaProp := HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) 

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'NOPLAYBAR ' + CurrentMediaProp + CRLF

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'PlayBar' , '.F.' )
				else
					__MVPUT( Name + 'PlayBar' , '.T.' )
				endif

			else

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'PlayBar' , '.F.' )
				else
					__MVPUT( Name + 'PlayBar' , '.T.' )
				endif

			endif

		///////////////////////////////////////////////////////////////
		// SHOWALL PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'SHOWALL'

			CurrentMediaProp := HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) 

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'SHOWALL ' + CurrentMediaProp + CRLF

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'ShowAll' , '.T.' )
				else
					__MVPUT( Name + 'ShowAll' , '.F.' )
				endif

			else

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'ShowAll' , '.T.' )
				else
					__MVPUT( Name + 'ShowAll' , '.F.' )
				endif

			endif

		///////////////////////////////////////////////////////////////
		// BREAK PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'BREAK'

			CurrentMediaProp := HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) 

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'BREAK ' + CurrentMediaProp + CRLF

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'Break' , '.T.' )
				else
					__MVPUT( Name + 'Break' , '.F.' )
				endif

			endif

		///////////////////////////////////////////////////////////////
		// SHOWMODE PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'SHOWMODE'

			CurrentMediaProp := HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) 

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'SHOWMODE ' + CurrentMediaProp + CRLF

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'ShowMode' , '.T.' )
				else
					__MVPUT( Name + 'ShowMode' , '.F.' )
				endif

			else

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'ShowMode' , '.T.' )
				else
					__MVPUT( Name + 'ShowMode' , '.F.' )
				endif

			endif

		///////////////////////////////////////////////////////////////
		// SHOWNAME PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'SHOWNAME'

			CurrentMediaProp := HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) 

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'SHOWNAME ' + CurrentMediaProp + CRLF

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'ShowName' , '.T.' )
				else
					__MVPUT( Name + 'ShowName' , '.F.' )
				endif

			else

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'ShowName' , '.T.' )
				else
					__MVPUT( Name + 'ShowName' , '.F.' )
				endif

			endif

		///////////////////////////////////////////////////////////////
		// SHOWPOSITION PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'SHOWPOSITION'

			CurrentMediaProp := HB_USUBSTR ( Line , 14 , HMG_LEN (Line) - 13 ) 

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'SHOWPOSITION ' + CurrentMediaProp + CRLF

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'ShowPosition' , '.T.' )
				else
					__MVPUT( Name + 'ShowPosition' , '.F.' )
				endif

			else

				if ALLTRIM(HMG_UPPER(CurrentMediaProp)) == '.T.'
					__MVPUT( Name + 'ShowPosition' , '.T.' )
				else
					__MVPUT( Name + 'ShowPosition' , '.F.' )
				endif

			endif

		///////////////////////////////////////////////////////////////
		// ROW PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ROW'

			CurrentRow := VAL ( HB_USUBSTR ( Line , 5 , HMG_LEN (Line) - 4 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ROW Nil' + CRLF

				__MVPUT ( Name + 'Row' , 'Nil' )

			else
	
				ROW CurrentRow

			endif

		///////////////////////////////////////////////////////////////
		// COL PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'COL'

			CurrentCol := VAL ( HB_USUBSTR ( Line , 5 , HMG_LEN (Line) - 4 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'COL Nil' + CRLF

				__MVPUT ( Name + 'Col' , 'Nil' )

			else
	
				COL CurrentCol

			endif





		///////////////////////////////////////////////////////////////
		// LOCKCOLUMNS PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'LOCKCOLUMNS '

			CurrentLockColumns := VAL ( HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'LOCKCOLUMNS ' + ALLTRIM ( STR ( CurrentLockColumns ) ) + CRLF

			endif

			__MVPUT ( Name + 'LockColumns' , ALLTRIM ( STR ( CurrentLockColumns ) ) )


		///////////////////////////////////////////////////////////////
		// WIDTH PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'WIDTH '

			CurrentWidth := VAL ( HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'WIDTH ' + ALLTRIM ( STR ( CurrentWidth ) ) + CRLF

				__MVPUT ( Name + 'Width' , ALLTRIM ( STR ( CurrentWidth ) ) )

			else
	
				WIDTH CurrentWidth

			endif

		///////////////////////////////////////////////////////////////
		// HEIGHT PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'HEIGHT'

			CurrentHeight := VAL ( HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )

			if _hmgide_SplitBoxProcessing == .T.

				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'HEIGHT ' + ALLTRIM ( STR ( CurrentHeight ) ) + CRLF

				__MVPUT ( Name + 'Height' , ALLTRIM ( STR ( CurrentHeight ) ) )

			else
	
				HEIGHT CurrentHeight

			endif

		///////////////////////////////////////////////////////////////
		// PROGID PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'PROGID'

			CurrentProgId := HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 )


			if	HB_ULEFT ( CurrentProgId , 1 ) == '"' ;
				.or. ;
				HB_ULEFT ( CurrentProgId , 1 ) == "'"

				CurrentProgId := HB_URIGHT (CurrentProgId , HMG_LEN(CurrentProgId) - 1 )

			EndIf

			if	HB_URIGHT ( CurrentProgId , 1 ) == '"' ;
				.or. ;
				HB_URIGHT ( CurrentProgId , 1 ) == "'"

				CurrentProgId := HB_ULEFT (CurrentProgId , HMG_LEN(CurrentProgId) - 1 )

			EndIf

			__MVPUT( Name + 'PROGID' , CurrentProgId )

		///////////////////////////////////////////////////////////////
		// CAPTION PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'CAPTION'

			If ControlType == 'BUTTON'

				CurrentCaption := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentCaption , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentCaption , 1 ) == "'"

					CurrentCaption := HB_URIGHT (CurrentCaption , HMG_LEN(CurrentCaption) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentCaption , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentCaption , 1 ) == "'"

					CurrentCaption := HB_ULEFT (CurrentCaption , HMG_LEN(CurrentCaption) - 1 )

				EndIf

				If   HMG_UPPER(CurrentCaption) == "NIL"
                                     CurrentCaption := ""
                                EndIf

				__MVPUT( Name + 'Caption' , CurrentCaption )

				CAPTION CurrentCaption

			ElseIf ControlType == 'CHECKBOX'

				CurrentCaption := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentCaption , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentCaption , 1 ) == "'" 

					CurrentCaption := HB_URIGHT (CurrentCaption , HMG_LEN(CurrentCaption) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentCaption , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentCaption , 1 ) == "'"

					CurrentCaption := HB_ULEFT (CurrentCaption , HMG_LEN(CurrentCaption) - 1 )

				EndIf

				__MVPUT( Name + 'Caption' , CurrentCaption )

				CAPTION CurrentCaption

			ElseIf ControlType == 'CHECKBUTTON'

				CurrentCaption := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentCaption , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentCaption , 1 ) == "'" 

					CurrentCaption := HB_URIGHT (CurrentCaption , HMG_LEN(CurrentCaption) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentCaption , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentCaption , 1 ) == "'"

					CurrentCaption := HB_ULEFT (CurrentCaption , HMG_LEN(CurrentCaption) - 1 )

				EndIf

				__MVPUT( Name + 'Caption' , CurrentCaption )

				CAPTION CurrentCaption

			ElseIf ControlType == 'FRAME'

				CurrentCaption := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentCaption , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentCaption , 1 ) == "'" 

					CurrentCaption := HB_URIGHT (CurrentCaption , HMG_LEN(CurrentCaption) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentCaption , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentCaption , 1 ) == "'"

					CurrentCaption := HB_ULEFT (CurrentCaption , HMG_LEN(CurrentCaption) - 1 )

				EndIf

				if ALLTRIM(HMG_UPPER(CurrentCaption)) == 'NIL'

					__MVPUT( Name + 'Caption' , "" )
					CurrentCaption := ""
					CAPTION ""
				
				else

					__MVPUT( Name + 'Caption' , CurrentCaption )
					CAPTION CurrentCaption

				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// TOP PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'TOP'

			If ControlType == 'SLIDER'

				CurrentTop := ALLTRIM(HB_USUBSTR ( Line , 5 , HMG_LEN (Line) - 4 ) )

				if ALLTRIM(HMG_UPPER(CurrentTop)) == ".T."
					__MVPUT( Name + 'TickMarks' , 'TOP' )
					TOP .T.
				endif

			EndIf


		///////////////////////////////////////////////////////////////
		// CASECONVERT PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'CASECONVERT LOWER'

			__MVPUT( Name + 'CaseConvert' , 'LOWER' )

		ElseIf	HMG_UPPER (Line) = 'CASECONVERT UPPER'

			__MVPUT( Name + 'CaseConvert' , 'UPPER' )

		ElseIf	HMG_UPPER (Line) = 'CASECONVERT NONE'

			__MVPUT( Name + 'CaseConvert' , 'NONE' )

		///////////////////////////////////////////////////////////////
		// UPPERCASE PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'UPPERCASE'

			If ControlType == 'TEXTBOX'

				CurrentUpperCase := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

				if ALLTRIM(HMG_UPPER(CurrentUpperCase)) == ".T."
					__MVPUT( Name + 'CaseConvert' , 'UPPER' )
				endif

			EndIf


		///////////////////////////////////////////////////////////////
		// DRAGITEMS PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'DRAGITEMS'

			CurrentDragItems := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

			if _hmgide_SplitBoxProcessing == .T.
				_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'DRAGITEMS ' + CurrentDragItems + CRLF
			endif

			if ALLTRIM(HMG_UPPER(CurrentDragItems)) == ".T."
				__MVPUT( Name + 'DragItems' , '.T.' )
			else
				__MVPUT( Name + 'DragItems' , '.F.' )
			endif

		///////////////////////////////////////////////////////////////
		// LOWERCASE PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'LOWERCASE'

			If ControlType == 'TEXTBOX'

				CurrentLowerCase := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

				if ALLTRIM(HMG_UPPER(CurrentLowerCase)) == ".T."
					__MVPUT( Name + 'CaseConvert' , 'LOWER' )
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// BOTH PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'BOTH'

			If ControlType == 'SLIDER'

				CurrentBoth := ALLTRIM(HB_USUBSTR ( Line , 6 , HMG_LEN (Line) - 5 ) )

				if ALLTRIM(HMG_UPPER(CurrentBoth)) == ".T."
					__MVPUT( Name + 'TickMarks' , 'BOTH' )
					BOTH .T.
				endif

			EndIf
		///////////////////////////////////////////////////////////////
		// NOTICKS PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'NOTICKS'

			If ControlType == 'SLIDER'

				CurrentNoticks := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if ALLTRIM(HMG_UPPER(CurrentNoTicks)) == ".T."
					__MVPUT( Name + 'TickMarks' , 'NONE' )
					NOTICKS .T.
				endif

			EndIf
		///////////////////////////////////////////////////////////////
		// LEFT PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'LEFT'

			If ControlType == 'SLIDER'

				CurrentLeft := ALLTRIM(HB_USUBSTR ( Line , 6 , HMG_LEN (Line) - 5 ) )

				if ALLTRIM(HMG_UPPER(CurrentLeft)) == ".T."
					__MVPUT( Name + 'TickMarks' , 'LEFT' )
					LEFT .T.
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// VERTICAL PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'VERTICAL'

			If ControlType == 'SLIDER'

				CurrentVertical := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if ALLTRIM(HMG_UPPER(CurrentVertical)) == ".T."
					__MVPUT( Name + 'Orientation' , 'VERTICAL' )
					VERTICAL .T.
				endif

			ElseIf ControlType == 'PROGRESSBAR'

				CurrentVertical := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if ALLTRIM(HMG_UPPER(CurrentVertical)) == ".T."
					__MVPUT( Name + 'Orientation' , 'VERTICAL' )
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// HORIZONTAL PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'HORIZONTAL'

			If ControlType == 'RADIOGROUP'

				CurrentHorizontal := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )

				if ALLTRIM(HMG_UPPER(CurrentHorizontal)) == ".T."

					__MVPUT( Name + 'Orientation' , 'HORIZONTAL' )
					HORIZONTAL .T.
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// ITEMSOURCE PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ITEMSOURCE'

			If ControlType == 'COMBOBOX'

				CurrentItemSource := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ITEMSOURCE ' + CurrentItemSource + CRLF
				endif

				__MVPUT( Name + 'ItemSource' , CurrentItemSource )

			EndIf

		///////////////////////////////////////////////////////////////
		// VALUESOURCE PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'VALUESOURCE'

			If ControlType == 'COMBOBOX'

				CurrentValueSource := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'VALUESOURCE ' + CurrentValueSource + CRLF
				endif

				__MVPUT( Name + 'ValueSource' , CurrentValueSource )

			EndIf

		///////////////////////////////////////////////////////////////
		// FIELD PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'FIELD '

			If ControlType == 'CHECKBOX'

				CurrentField := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				__MVPUT( Name + 'Field' , CurrentField )

			ElseIf ControlType == 'DATEPICKER'

				CurrentField := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				__MVPUT( Name + 'Field' , CurrentField )

			ElseIf ControlType == 'TEXTBOX'

				CurrentField := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				__MVPUT( Name + 'Field' , CurrentField )

			ElseIf ControlType == 'EDITBOX'

				CurrentField := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FIELD ' + CurrentField + CRLF
				endif

				__MVPUT( Name + 'Field' , CurrentField )

			ElseIf ControlType == 'RICHEDITBOX'

				CurrentField := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FIELD ' + CurrentField + CRLF
				endif

				__MVPUT( Name + 'Field' , CurrentField )

			EndIf

		///////////////////////////////////////////////////////////////
		// ACTION EVENT
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ACTION'

			If ControlType == 'BUTTON'

				CurrentAction := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'Action' , CurrentAction )

			ElseIf ControlType == 'IMAGE'

				CurrentAction := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'Action' , CurrentAction )

			ElseIf ControlType == 'LABEL'

				CurrentAction := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'Action' , CurrentAction )

			EndIf

		///////////////////////////////////////////////////////////////
		// ITEMS PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ITEMS'

			If ControlType == 'LISTBOX'

				CurrentItems := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ITEMS ' + CurrentItems + CRLF
				endif

				__MVPUT( Name + 'Items' , CurrentItems )

			ElseIf ControlType == 'COMBOBOX'

				CurrentItems := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ITEMS ' + CurrentItems + CRLF
				endif

				__MVPUT( Name + 'Items' , CurrentItems )

			ElseIf ControlType == 'GRID'

				CurrentItems := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ITEMS ' + CurrentItems + CRLF
				endif

				__MVPUT( Name + 'Items' , CurrentItems )

			EndIf

		///////////////////////////////////////////////////////////////
		// SHOWHEADERS PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'SHOWHEADERS'

			If ControlType == 'GRID'

				CurrentShowHeaders := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'SHOWHEADERS ' + CurrentShowHeaders + CRLF
				endif

				__MVPUT( Name + 'ShowHeaders' , CurrentShowHeaders )

			EndIf

		///////////////////////////////////////////////////////////////
		// RANGEMAX PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'RANGEMAX'

			If ControlType == 'SLIDER'

				CurrentRangeMax := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'RangeMax' , CurrentRangeMax )

			ElseIf ControlType == 'SPINNER'

				CurrentRangeMax := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'RangeMax' , CurrentRangeMax )

			ElseIf ControlType == 'PROGRESSBAR'

				CurrentRangeMax := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'RangeMax' , CurrentRangeMax )

			EndIf

		///////////////////////////////////////////////////////////////
		// RANGEMIN PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'RANGEMIN'

			If ControlType == 'SLIDER'

				CurrentRangeMin := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'RangeMin' , CurrentRangeMin )

			ElseIf ControlType == 'SPINNER'

				CurrentRangeMin := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'RangeMin' , CurrentRangeMin )

			ElseIf ControlType == 'PROGRESSBAR'

				CurrentRangeMin := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'RangeMin' , CurrentRangeMin )

			EndIf

		///////////////////////////////////////////////////////////////
		// PICTURE PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'PICTURE'

			If	ControlType == 'BUTTON'

				CurrentPicture := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentPicture , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentPicture , 1 ) == "'" 

					CurrentPicture := HB_URIGHT ( CurrentPicture , HMG_LEN( CurrentPicture ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentPicture , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentPicture , 1 ) == "'"

					CurrentPicture := HB_ULEFT ( CurrentPicture , HMG_LEN( CurrentPicture ) - 1 )

				EndIf

				if ALLTRIM ( HMG_UPPER (CurrentPicture) ) == 'NIL'
					CurrentPicture := ''
				endif

				__MVPUT( Name + 'Picture' , CurrentPicture )

			ElseIf	ControlType == 'CHECKBUTTON'

				CurrentPicture := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentPicture , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentPicture , 1 ) == "'" 

					CurrentPicture := HB_URIGHT ( CurrentPicture , HMG_LEN( CurrentPicture ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentPicture , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentPicture , 1 ) == "'"

					CurrentPicture := HB_ULEFT ( CurrentPicture , HMG_LEN( CurrentPicture ) - 1 )

				EndIf

				if ALLTRIM ( HMG_UPPER (CurrentPicture) ) == 'NIL'
					CurrentPicture := ''
				endif

				__MVPUT( Name + 'Picture' , CurrentPicture )

			ElseIf ControlType == 'IMAGE'

				CurrentPicture := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentPicture , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentPicture , 1 ) == "'" 

					CurrentPicture := HB_URIGHT (CurrentPicture , HMG_LEN(CurrentPicture) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentPicture , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentPicture , 1 ) == "'"

					CurrentPicture := HB_ULEFT (CurrentPicture , HMG_LEN(CurrentPicture) - 1 )

				EndIf

				__MVPUT( Name + 'Picture' , CurrentPicture )

			EndIf

		///////////////////////////////////////////////////////////////
		// PICTALIGNMENT PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'PICTALIGNMENT'

			If	ControlType == 'BUTTON'

				CurrentPictAlignment := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )

				__MVPUT( Name + 'PictAlignment' , CurrentPictAlignment )

			EndIf

		///////////////////////////////////////////////////////////////
		// INCREMENT PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'INCREMENT'

			If ControlType == 'SPINNER'

				CurrentIncrement := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

				__MVPUT( Name + 'Increment' , CurrentIncrement )
			
			EndIf

		///////////////////////////////////////////////////////////////
		// MAXLENGTH PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'MAXLENGTH'

			If ControlType == 'TEXTBOX'

				CurrentMaxLength := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

				__MVPUT( Name + 'MaxLength' , CurrentMaxLength )
			
			ElseIf ControlType == 'EDITBOX'

				CurrentMaxLength := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'MAXLENGTH ' + CurrentMaxLength + CRLF
				endif

				__MVPUT( Name + 'MaxLength' , CurrentMaxLength )

			ElseIf ControlType == 'RICHEDITBOX'

				CurrentMaxLength := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'MAXLENGTH ' + CurrentMaxLength + CRLF
				endif

				__MVPUT( Name + 'MaxLength' , CurrentMaxLength )
			
			EndIf

		///////////////////////////////////////////////////////////////
		// VALUE PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'VALUE'

			If ControlType == 'DATEPICKER'

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				__MVPUT( Name + 'Value' , CurrentValue )

			ElseIf ControlType == 'TEXTBOX'

				QuoteFlag := .F.

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				if	HB_ULEFT ( CurrentValue , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentValue , 1 ) == "'" 

					CurrentValue := HB_URIGHT (CurrentValue , HMG_LEN(CurrentValue) - 1 )

					QuoteFlag := .T.

				EndIf

				if	HB_URIGHT ( CurrentValue , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentValue , 1 ) == "'"

					CurrentValue := HB_ULEFT (CurrentValue , HMG_LEN(CurrentValue) - 1 )

					QuoteFlag := .T.

				EndIf

				if	QuoteFlag == .T. 

					__MVPUT( Name + 'Value' , CurrentValue )

				Elseif 	HMG_UPPER(ALLTRIM(CurrentValue)) == 'NIL'

					__MVPUT( Name + 'Value' , '' )

				Else

					__MVPUT( Name + 'Value' , CurrentValue )

				EndIf

			ElseIf ControlType == 'EDITBOX'

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				if	HB_ULEFT ( CurrentValue , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentValue , 1 ) == "'" 

					CurrentValue := HB_URIGHT (CurrentValue , HMG_LEN(CurrentValue) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentValue , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentValue , 1 ) == "'"

					CurrentValue := HB_ULEFT (CurrentValue , HMG_LEN(CurrentValue) - 1 )

				EndIf

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'VALUE ' + '"' + CurrentValue + '"' + CRLF
				endif

				__MVPUT( Name + 'Value' , CurrentValue )

			ElseIf ControlType == 'LABEL'

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				if	HB_ULEFT ( CurrentValue , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentValue , 1 ) == "'" 

					CurrentValue := HB_URIGHT (CurrentValue , HMG_LEN(CurrentValue) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentValue , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentValue , 1 ) == "'"

					CurrentValue := HB_ULEFT (CurrentValue , HMG_LEN(CurrentValue) - 1 )

				EndIf

				__MVPUT( Name + 'Value' , CurrentValue )

				VALUE CurrentValue

			ElseIf ControlType == 'BROWSE'

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'VALUE ' + CurrentValue + CRLF
				endif

				__MVPUT( Name + 'Value' , CurrentValue )

			ElseIf ControlType == 'GRID'

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'VALUE ' + CurrentValue + CRLF
				endif

				__MVPUT( Name + 'Value' , CurrentValue )

			ElseIf ControlType == 'HYPERLINK'

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				if	HB_ULEFT ( CurrentValue , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentValue , 1 ) == "'" 

					CurrentValue := HB_URIGHT (CurrentValue , HMG_LEN(CurrentValue) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentValue , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentValue , 1 ) == "'"

					CurrentValue := HB_ULEFT (CurrentValue , HMG_LEN(CurrentValue) - 1 )

				EndIf

				__MVPUT( Name + 'Value' , CurrentValue )

				VALUE CurrentValue

			ElseIf ControlType == 'RICHEDITBOX'

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				if	HB_ULEFT ( CurrentValue , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentValue , 1 ) == "'" 

					CurrentValue := HB_URIGHT (CurrentValue , HMG_LEN(CurrentValue) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentValue , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentValue , 1 ) == "'"

					CurrentValue := HB_ULEFT (CurrentValue , HMG_LEN(CurrentValue) - 1 )

				EndIf

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'VALUE ' + '"' + CurrentValue + '"' + CRLF
				endif

				__MVPUT( Name + 'Value' , CurrentValue )

			ElseIf ControlType == 'MONTHCALENDAR'

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				__MVPUT( Name + 'Value' , CurrentValue )

			ElseIf ControlType == 'IPADDRESS'

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				__MVPUT( Name + 'Value' , CurrentValue )

			ElseIf ControlType == 'LISTBOX'

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'VALUE ' + CurrentValue + CRLF
				endif

				__MVPUT( Name + 'Value' , CurrentValue )

			ElseIf ControlType == 'COMBOBOX'

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'VALUE ' + CurrentValue + CRLF
				endif

				__MVPUT( Name + 'Value' , CurrentValue )

			ElseIf ControlType == 'CHECKBUTTON'

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				__MVPUT( Name + 'Value' , CurrentValue )

			ElseIf ControlType == 'CHECKBOX'

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				__MVPUT( Name + 'Value' , CurrentValue )

			ElseIf ControlType == 'SPINNER'

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				__MVPUT( Name + 'Value' , CurrentValue )

			ElseIf ControlType == 'SLIDER'

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				__MVPUT( Name + 'Value' , CurrentValue )

			ElseIf ControlType == 'RADIOGROUP'

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				__MVPUT( Name + 'Value' , CurrentValue )

			ElseIf ControlType == 'PROGRESSBAR'

				CurrentValue := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				__MVPUT( Name + 'Value' , CurrentValue )


			EndIf

		///////////////////////////////////////////////////////////////
		// WORKAREA PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'WORKAREA'

			If ControlType == 'BROWSE'

				CurrentWorkArea := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'WORKAREA ' + CurrentWorkArea + CRLF
				endif

				__MVPUT( Name + 'WorkArea' , CurrentWorkArea )

			EndIf

		///////////////////////////////////////////////////////////////
		// FIELDS PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'FIELDS'

			If ControlType == 'BROWSE'

				CurrentFields := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FIELDS ' + CurrentFields + CRLF
				endif

				__MVPUT( Name + 'Fields' , CurrentFields )

			EndIf

		///////////////////////////////////////////////////////////////
		// VALID PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'VALID '

			If ControlType == 'BROWSE'

				CurrentValid := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'VALID ' + CurrentValid + CRLF
				endif

				__MVPUT( Name + 'Valid' , CurrentValid )

			EndIf

		///////////////////////////////////////////////////////////////
		// VALIDMESSAGES PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'VALIDMESSAGES'

			If ControlType == 'BROWSE'

				CurrentValidMessages := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'VALIDMESSAGES ' + CurrentValidMessages + CRLF
				endif

				__MVPUT( Name + 'ValidMessages' , CurrentValidMessages )

			EndIf

		///////////////////////////////////////////////////////////////
		// LOCK PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'LOCK'

			If ControlType == 'BROWSE'

				CurrentLock := ALLTRIM(HB_USUBSTR ( Line , 6 , HMG_LEN (Line) - 5 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'LOCK ' + CurrentLock + CRLF
				endif

				__MVPUT( Name + 'Lock' , CurrentLock )

			EndIf

		///////////////////////////////////////////////////////////////
		// DISABLEDBACKCOLOR PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'DISABLEDBACKCOLOR'

			If ControlType == 'EDITBOX'

				CurrentDisabledBackColor := ALLTRIM(HB_USUBSTR ( Line , 19 , HMG_LEN (Line) - 18 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'DISABLEDBACKCOLOR ' + CurrentDisabledBackColor + CRLF
				endif

				__MVPUT( Name + 'DisabledBackColor' , CurrentDisabledBackColor )


			ElseIf ControlType == 'TEXTBOX'

				CurrentDisabledBackColor := ALLTRIM(HB_USUBSTR ( Line , 19 , HMG_LEN (Line) - 18 ) )

				__MVPUT( Name + 'DisabledBackColor' , CurrentDisabledBackColor )

			EndIf

		///////////////////////////////////////////////////////////////
		// DISABLEDFONTCOLOR PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'DISABLEDFONTCOLOR'

			If ControlType == 'EDITBOX'

				CurrentDisabledFontColor := ALLTRIM(HB_USUBSTR ( Line , 19 , HMG_LEN (Line) - 18 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'DISABLEDFONTCOLOR ' + CurrentDisabledFontColor + CRLF
				endif

				__MVPUT( Name + 'DisabledFontColor' , CurrentDisabledFontColor )

			ElseIf ControlType == 'TEXTBOX'

				CurrentDisabledFontColor := ALLTRIM(HB_USUBSTR ( Line , 19 , HMG_LEN (Line) - 18 ) )

				__MVPUT( Name + 'DisabledFontColor' , CurrentDisabledFontColor )

			EndIf


		///////////////////////////////////////////////////////////////
		// VSCROLLBAR PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'VSCROLLBAR'

			If ControlType == 'BROWSE'

				CurrentvScrollBar := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'VSCROLLBAR ' + CurrentvScrollBar + CRLF
				endif

				__MVPUT( Name + 'vScrollBar' , CurrentvScrollBar )

			ElseIf ControlType == 'EDITBOX'

				CurrentvScrollBar := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'VSCROLLBAR ' + CurrentvScrollBar + CRLF
				endif

				__MVPUT( Name + 'vScrollBar' , CurrentvScrollBar )

			EndIf

		///////////////////////////////////////////////////////////////
		// HSCROLLBAR PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'HSCROLLBAR'

			If ControlType == 'EDITBOX'

				CurrenthScrollBar := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'HSCROLLBAR ' + CurrenthScrollBar + CRLF
				endif

				__MVPUT( Name + 'hScrollBar' , CurrenthScrollBar )

			EndIf

		///////////////////////////////////////////////////////////////
		// WIDTHS PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'WIDTHS'

			If ControlType == 'BROWSE'

				CurrentWidths := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'WIDTHS ' + CurrentWidths + CRLF
				endif

				__MVPUT( Name + 'Widths' , CurrentWidths )

			ElseIf ControlType == 'GRID'

				CurrentWidths := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'WIDTHS ' + CurrentWidths + CRLF
				endif

				__MVPUT( Name + 'Widths' , CurrentWidths )

			EndIf

		///////////////////////////////////////////////////////////////
		// ITEMCOUNT PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ITEMCOUNT'

			If ControlType == 'GRID'

				CurrentItemCount := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ITEMCOUNT ' + CurrentItemCount + CRLF
				endif

				__MVPUT( Name + 'ItemCount' , CurrentItemCount )

			EndIf


		///////////////////////////////////////////////////////////////
		// HEADERS PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'HEADERS'

			If ControlType == 'BROWSE'

				CurrentHeaders := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'HEADERS ' + CurrentHeaders + CRLF
				endif

				__MVPUT( Name + 'Headers' , CurrentHeaders )

			ElseIf ControlType == 'GRID'

				CurrentHeaders := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'HEADERS ' + CurrentHeaders + CRLF
				endif

				__MVPUT( Name + 'Headers' , CurrentHeaders )

			EndIf


		///////////////////////////////////////////////////////////////
		// HEADERIMAGES PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'HEADERIMAGES'

			If ControlType == 'BROWSE'

				CurrentHeaderImages := ALLTRIM(HB_USUBSTR ( Line , 14 , HMG_LEN (Line) - 13 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'HEADERIMAGES ' + CurrentHeaderImages + CRLF
				endif

				__MVPUT( Name + 'HeaderImages' , CurrentHeaderImages )

			ElseIf ControlType == 'GRID'

				CurrentHeaderImages := ALLTRIM(HB_USUBSTR ( Line , 14 , HMG_LEN (Line) - 13 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'HEADERIMAGES ' + CurrentHeaderImages + CRLF
				endif

				__MVPUT( Name + 'HeaderImages' , CurrentHeaderImages )

			EndIf


		///////////////////////////////////////////////////////////////
		// OPTIONS PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'OPTIONS'

			If ControlType == 'RADIOGROUP'

				CurrentOptions := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				__MVPUT( Name + 'Options' , CurrentOptions )

			EndIf

		///////////////////////////////////////////////////////////////
		// FILE PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'FILE'

			If ControlType == 'ANIMATEBOX'

				CurrentFile := ALLTRIM(HB_USUBSTR ( Line , 6 , HMG_LEN (Line) - 5 ) )

				if	HB_ULEFT ( CurrentFile , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFile , 1 ) == "'" 

					CurrentFile := HB_URIGHT (CurrentFile , HMG_LEN(CurrentFile) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFile , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFile , 1 ) == "'"

					CurrentFile := HB_ULEFT (CurrentFile , HMG_LEN(CurrentFile) - 1 )

				EndIf

				__MVPUBLIC ( Name + 'File' ) 
				__MVPUT( Name + 'File' , CurrentFile )

			ElseIf ControlType == 'PLAYER'

				CurrentFile := ALLTRIM(HB_USUBSTR ( Line , 6 , HMG_LEN (Line) - 5 ) )

				if	HB_ULEFT ( CurrentFile , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFile , 1 ) == "'" 

					CurrentFile := HB_URIGHT (CurrentFile , HMG_LEN(CurrentFile) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFile , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFile , 1 ) == "'"

					CurrentFile := HB_ULEFT (CurrentFile , HMG_LEN(CurrentFile) - 1 )

				EndIf

				__MVPUBLIC ( Name + 'File' ) 
				__MVPUT( Name + 'File' , CurrentFile )

			EndIf

		///////////////////////////////////////////////////////////////
		// ADDRESS PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ADDRESS'

			If ControlType == 'HYPERLINK'

				CurrentAddress := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentAddress , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentAddress , 1 ) == "'" 

					CurrentAddress := HB_URIGHT (CurrentAddress , HMG_LEN(CurrentAddress) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentAddress , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentAddress , 1 ) == "'"

					CurrentAddress := HB_ULEFT (CurrentAddress , HMG_LEN(CurrentAddress) - 1 )

				EndIf

				__MVPUT( Name + 'Address' , CurrentAddress )

			EndIf

		///////////////////////////////////////////////////////////////
		// FONTNAME PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'FONTNAME'

			If ControlType == 'BUTTON'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

				FONTNAME CurrentFontName

			ElseIf ControlType == 'CHECKBOX'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

				FONTNAME CurrentFontName

			ElseIf ControlType == 'LISTBOX'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTNAME ' + '"' + CurrentFontName + '"'  + CRLF
				else
					FONTNAME CurrentFontName
				endif

			ElseIf ControlType == 'COMBOBOX'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTNAME ' + '"' + CurrentFontName + '"' + CRLF
				else
					FONTNAME CurrentFontName
				endif

			ElseIf ControlType == 'CHECKBUTTON'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

				FONTNAME CurrentFontName

			ElseIf ControlType == 'GRID'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTNAME ' + '"' + CurrentFontName + '"' + CRLF
				else
					FONTNAME CurrentFontName
				endif

			ElseIf	ControlType == 'SPINNER'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

				FONTNAME CurrentFontName

			ElseIf	ControlType == 'DATEPICKER'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

				FONTNAME CurrentFontName

			ElseIf	ControlType == 'TEXTBOX'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

				FONTNAME CurrentFontName

			ElseIf	ControlType == 'EDITBOX'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTNAME ' + '"'  + CurrentFontName + '"'  + CRLF
				else
					FONTNAME CurrentFontName
				endif

			ElseIf	ControlType == 'LABEL'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

				FONTNAME CurrentFontName

			ElseIf	ControlType == 'BROWSE'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTNAME ' + '"' + CurrentFontName + '"' + CRLF
				else
					FONTNAME CurrentFontName
				endif

			ElseIf	ControlType == 'RADIOGROUP'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

				FONTNAME CurrentFontName

			ElseIf	ControlType == 'FRAME'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

				FONTNAME CurrentFontName

			ElseIf	ControlType == 'HYPERLINK'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

				FONTNAME CurrentFontName

			ElseIf	ControlType == 'MONTHCALENDAR'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

				FONTNAME CurrentFontName

			ElseIf	ControlType == 'RICHEDITBOX'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTNAME ' + '"' + CurrentFontName + '"'  + CRLF
				else
					FONTNAME CurrentFontName
				endif

			ElseIf	ControlType == 'IPADDRESS'

				CurrentFontName := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				if	HB_ULEFT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFontName , 1 ) == "'" 

					CurrentFontName := HB_URIGHT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFontName , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFontName , 1 ) == "'"

					CurrentFontName := HB_ULEFT ( CurrentFontName , HMG_LEN( CurrentFontName ) - 1 )

				EndIf

				__MVPUT( Name + 'FontName' , CurrentFontName )

			EndIf

		///////////////////////////////////////////////////////////////
		// HELPID PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'HELPID'
			If ControlType == 'BUTTON'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )
			ElseIf ControlType == 'CHECKBOX'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )
			ElseIf ControlType == 'LISTBOX'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'HELPID ' + CurrentHelpId + CRLF
				endif

			ElseIf ControlType == 'COMBOBOX'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'HELPID ' + CurrentHelpId + CRLF
				endif

			ElseIf ControlType == 'CHECKBUTTON'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )
			ElseIf ControlType == 'GRID'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'HELPID ' + CurrentHelpId + CRLF
				endif

			ElseIf ControlType == 'SLIDER'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )
			ElseIf ControlType == 'SPINNER'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )
			ElseIf ControlType == 'IMAGE'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )
			ElseIf ControlType == 'DATEPICKER'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )
			ElseIf ControlType == 'TEXTBOX'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )
			ElseIf ControlType == 'EDITBOX'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'HELPID ' + CurrentHelpId + CRLF
				endif

			ElseIf ControlType == 'LABEL'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )
			ElseIf ControlType == 'IPADDRESS'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )
			ElseIf ControlType == 'BROWSE'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'HELPID ' + CurrentHelpId + CRLF
				endif

			ElseIf ControlType == 'RADIOGROUP'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )
			ElseIf ControlType == 'PLAYER'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )
			ElseIf ControlType == 'PROGRESSBAR'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )
			ElseIf ControlType == 'RICHEDITBOX'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'HELPID ' + CurrentHelpId + CRLF
				endif

			ElseIf ControlType == 'MONTHCALENDAR'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )
			ElseIf ControlType == 'HYPERLINK'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )
			ElseIf ControlType == 'ANIMATEBOX'
				CurrentHelpId := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'HelpId' , CurrentHelpId )
			EndIf

		///////////////////////////////////////////////////////////////
		// BACKCOLOR PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'BACKCOLOR'
			If ControlType == 'CHECKBOX'
				CurrentBackColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
					__MVPUT( Name + 'BackColor' , CurrentBackColor )
					BACKCOLOR &CurrentBackColor
				Else
					__MVPUT( Name + 'BackColor' , 'NIL' )
				endif
			ElseIf ControlType == 'LISTBOX'
				CurrentBackColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'BACKCOLOR ' + CurrentBackColor + CRLF

					if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
						__MVPUT( Name + 'BackColor' , CurrentBackColor )
					Else
						__MVPUT( Name + 'BackColor' , 'NIL' )
					endif

				else

					if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
						__MVPUT( Name + 'BackColor' , CurrentBackColor )
						BACKCOLOR &CurrentBackColor
					Else
						__MVPUT( Name + 'BackColor' , 'NIL' )
					endif

				endif

			ElseIf ControlType == 'GRID'
				CurrentBackColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'BACKCOLOR ' + CurrentBackColor + CRLF

					if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
						__MVPUT( Name + 'BackColor' , CurrentBackColor )
					Else
						__MVPUT( Name + 'BackColor' , 'NIL' )
					endif

				else

					if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
						__MVPUT( Name + 'BackColor' , CurrentBackColor )
						BACKCOLOR &CurrentBackColor
					Else
						__MVPUT( Name + 'BackColor' , 'NIL' )
					endif

				endif

			ElseIf ControlType == 'SLIDER'
				CurrentBackColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
					__MVPUT( Name + 'BackColor' , CurrentBackColor )
					BACKCOLOR &CurrentBackColor
				Else
					__MVPUT( Name + 'BackColor' , 'NIL' )
				endif
			ElseIf ControlType == 'SPINNER'
				CurrentBackColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
					__MVPUT( Name + 'BackColor' , CurrentBackColor )
					BACKCOLOR &CurrentBackColor
				Else
					__MVPUT( Name + 'BackColor' , 'NIL' )
				endif
			ElseIf ControlType == 'TEXTBOX'
				CurrentBackColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
					__MVPUT( Name + 'BackColor' , CurrentBackColor )
					BACKCOLOR &CurrentBackColor
				Else
					__MVPUT( Name + 'BackColor' , 'NIL' )
				endif
			ElseIf ControlType == 'EDITBOX'
				CurrentBackColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'BACKCOLOR ' + CurrentBackColor + CRLF

					if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
						__MVPUT( Name + 'BackColor' , CurrentBackColor )
					Else
						__MVPUT( Name + 'BackColor' , 'NIL' )
					endif

				else

					if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
						__MVPUT( Name + 'BackColor' , CurrentBackColor )
						BACKCOLOR &CurrentBackColor
					Else
						__MVPUT( Name + 'BackColor' , 'NIL' )
					endif

				endif


			ElseIf ControlType == 'LABEL'
				CurrentBackColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
					__MVPUT( Name + 'BackColor' , CurrentBackColor )
					BACKCOLOR &CurrentBackColor
				Else
					__MVPUT( Name + 'BackColor' , 'NIL' )
				endif
			ElseIf ControlType == 'BROWSE'
				CurrentBackColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'BACKCOLOR ' + CurrentBackColor + CRLF

					if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
						__MVPUT( Name + 'BackColor' , CurrentBackColor )
					Else
						__MVPUT( Name + 'BackColor' , 'NIL' )
					endif

				else

					if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
						__MVPUT( Name + 'BackColor' , CurrentBackColor )
						BACKCOLOR &CurrentBackColor
					Else
						__MVPUT( Name + 'BackColor' , 'NIL' )
					endif

				endif

			ElseIf ControlType == 'RADIOGROUP'
				CurrentBackColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
					__MVPUT( Name + 'BackColor' , CurrentBackColor )
				Else
					__MVPUT( Name + 'BackColor' , 'NIL' )
				endif
			ElseIf ControlType == 'FRAME'
				CurrentBackColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
					__MVPUT( Name + 'BackColor' , CurrentBackColor )
					BACKCOLOR &CurrentBackColor
				Else
					__MVPUT( Name + 'BackColor' , 'NIL' )
				endif
			ElseIf ControlType == 'PROGRESSBAR'
				CurrentBackColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
					__MVPUT( Name + 'BackColor' , CurrentBackColor )
				Else
					__MVPUT( Name + 'BackColor' , 'NIL' )
				endif
			ElseIf ControlType == 'RICHEDITBOX'
				CurrentBackColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'BACKCOLOR ' + CurrentBackColor + CRLF

					if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
						__MVPUT( Name + 'BackColor' , CurrentBackColor )
					Else
						__MVPUT( Name + 'BackColor' , 'NIL' )
					endif

				else

					if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
						__MVPUT( Name + 'BackColor' , CurrentBackColor )
						BACKCOLOR &CurrentBackColor
					Else
						__MVPUT( Name + 'BackColor' , 'NIL' )
					endif

				endif

			ElseIf ControlType == 'HYPERLINK'
				CurrentBackColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				if HB_ULEFT ( CurrentBackColor , 1 ) == '{'
					__MVPUT( Name + 'BackColor' , CurrentBackColor )
					BACKCOLOR &CurrentBackColor
				Else
					__MVPUT( Name + 'BackColor' , 'NIL' )
				endif
			EndIf
		///////////////////////////////////////////////////////////////
		// FONTCOLOR PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'FONTCOLOR'
			If ControlType == 'CHECKBOX'
				CurrentFontColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				if HB_ULEFT ( CurrentFontColor , 1 ) == '{'
					__MVPUT( Name + 'FontColor' , CurrentFontColor )
					FONTCOLOR &CurrentFontColor
				else
					__MVPUT( Name + 'FontColor' , 'NIL' )
				endif
			ElseIf ControlType == 'LISTBOX'

				CurrentFontColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTCOLOR ' + CurrentFontColor + CRLF

					if HB_ULEFT ( CurrentFontColor , 1 ) == '{'
						__MVPUT( Name + 'FontColor' , CurrentFontColor )
					else
						__MVPUT( Name + 'FontColor' , 'NIL' )
					endif

				else

					if HB_ULEFT ( CurrentFontColor , 1 ) == '{'
						__MVPUT( Name + 'FontColor' , CurrentFontColor )
						FONTCOLOR &CurrentFontColor
					else
						__MVPUT( Name + 'FontColor' , 'NIL' )
					endif

				endif

			ElseIf ControlType == 'GRID'
				CurrentFontColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTCOLOR ' + CurrentFontColor + CRLF

					if HB_ULEFT ( CurrentFontColor , 1 ) == '{'
						__MVPUT( Name + 'FontColor' , CurrentFontColor )
					else
						__MVPUT( Name + 'FontColor' , 'NIL' )
					endif

				else

					if HB_ULEFT ( CurrentFontColor , 1 ) == '{'
						__MVPUT( Name + 'FontColor' , CurrentFontColor )
						FONTCOLOR &CurrentFontColor
					else
						__MVPUT( Name + 'FontColor' , 'NIL' )
					endif

				endif

			ElseIf ControlType == 'SPINNER'
				CurrentFontColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				if HB_ULEFT ( CurrentFontColor , 1 ) == '{'
					__MVPUT( Name + 'FontColor' , CurrentFontColor )
					FONTCOLOR &CurrentFontColor
				else
					__MVPUT( Name + 'FontColor' , 'NIL' )
				endif
			ElseIf ControlType == 'TEXTBOX'
				CurrentFontColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				if HB_ULEFT ( CurrentFontColor , 1 ) == '{'
					__MVPUT( Name + 'FontColor' , CurrentFontColor )
					FONTCOLOR &CurrentFontColor
				else
					__MVPUT( Name + 'FontColor' , 'NIL' )
				endif
			ElseIf ControlType == 'EDITBOX'

				CurrentFontColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTCOLOR ' + CurrentFontColor + CRLF

					if HB_ULEFT ( CurrentFontColor , 1 ) == '{'
						__MVPUT( Name + 'FontColor' , CurrentFontColor )
					else
						__MVPUT( Name + 'FontColor' , 'NIL' )
					endif

				else

					if HB_ULEFT ( CurrentFontColor , 1 ) == '{'
						__MVPUT( Name + 'FontColor' , CurrentFontColor )
						FONTCOLOR &CurrentFontColor
					else
						__MVPUT( Name + 'FontColor' , 'NIL' )
					endif

				endif

			ElseIf ControlType == 'LABEL'
				CurrentFontColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				if HB_ULEFT ( CurrentFontColor , 1 ) == '{'
					__MVPUT( Name + 'FontColor' , CurrentFontColor )
					FONTCOLOR &CurrentFontColor
				else
					__MVPUT( Name + 'FontColor' , 'NIL' )
				endif
			ElseIf ControlType == 'BROWSE'
				CurrentFontColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTCOLOR ' + CurrentFontColor + CRLF

					if HB_ULEFT ( CurrentFontColor , 1 ) == '{'
						__MVPUT( Name + 'FontColor' , CurrentFontColor )
					else
						__MVPUT( Name + 'FontColor' , 'NIL' )
					endif

				else

					if HB_ULEFT ( CurrentFontColor , 1 ) == '{'
						__MVPUT( Name + 'FontColor' , CurrentFontColor )
						FONTCOLOR &CurrentFontColor
					else
						__MVPUT( Name + 'FontColor' , 'NIL' )
					endif

				endif

			ElseIf ControlType == 'RADIOGROUP'
				CurrentFontColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				if HB_ULEFT ( CurrentFontColor , 1 ) == '{'
					__MVPUT( Name + 'FontColor' , CurrentFontColor )
				else
					__MVPUT( Name + 'FontColor' , 'NIL' )
				endif
			ElseIf ControlType == 'FRAME'
				CurrentFontColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				if HB_ULEFT ( CurrentFontColor , 1 ) == '{'
					__MVPUT( Name + 'FontColor' , CurrentFontColor )
					FONTCOLOR &CurrentFontColor
				else
					__MVPUT( Name + 'FontColor' , 'NIL' )
				endif
			ElseIf ControlType == 'HYPERLINK'
				CurrentFontColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				if HB_ULEFT ( CurrentFontColor , 1 ) == '{'
					__MVPUT( Name + 'FontColor' , CurrentFontColor )
					FONTCOLOR &CurrentFontColor
				else
					__MVPUT( Name + 'FontColor' , 'NIL' )
				endif
			EndIf

		///////////////////////////////////////////////////////////////
		// FORECOLOR PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'FORECOLOR'
			If ControlType == 'PROGRESSBAR'
				CurrentFontColor := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				if HB_ULEFT ( CurrentFontColor , 1 ) == '{'
					__MVPUT( Name + 'ForeColor' , CurrentFontColor )
				else
					__MVPUT( Name + 'ForeColor' , 'NIL' )
				endif
			endif

		///////////////////////////////////////////////////////////////
		// DISPLAYEDIT PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'DISPLAYEDIT'
			If ControlType == 'COMBOBOX'

				CurrentDisplayEdit := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )

				__MVPUT( Name + 'DisplayEdit' , CurrentDisplayEdit )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'DISPLAYEDIT ' + CurrentDisplayEdit + CRLF
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// DROPPEDWIDTH PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'DROPPEDWIDTH'
			If ControlType == 'COMBOBOX'

				CurrentDroppedWidth := ALLTRIM(HB_USUBSTR ( Line , 14 , HMG_LEN (Line) - 13 ) )

				__MVPUT( Name + 'DroppedWidth' , CurrentDroppedWidth )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'DROPPEDWIDTH ' + CurrentDroppedWidth + CRLF
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// JUSTIFY PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'JUSTIFY'
			If ControlType == 'GRID'
				CurrentJustify := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Justify' , CurrentJustify )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'JUSTIFY ' + CurrentJustify + CRLF
				endif

			ElseIf ControlType == 'BROWSE'
				CurrentJustify := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Justify' , CurrentJustify )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'JUSTIFY ' + CurrentJustify + CRLF
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// IMAGE PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'IMAGE'
			If ControlType == 'GRID'
				CurrentImage := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )
				__MVPUT( Name + 'Image' , CurrentImage )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'IMAGE ' + CurrentImage + CRLF
				endif

			ElseIf ControlType == 'BROWSE'
				CurrentImage := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )
				__MVPUT( Name + 'Image' , CurrentImage )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'IMAGE ' + CurrentImage + CRLF
				endif

			ElseIf ControlType == 'COMBOBOX'
				CurrentImage := ALLTRIM(HB_USUBSTR ( Line , 7 , HMG_LEN (Line) - 6 ) )
				__MVPUT( Name + 'Image' , CurrentImage )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'IMAGE ' + CurrentImage + CRLF
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// WRAP PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'WRAP'
			If ControlType == 'SPINNER'
				CurrentWrap := ALLTRIM(HB_USUBSTR ( Line , 6 , HMG_LEN (Line) - 5 ) )
				__MVPUT( Name + 'Wrap' , CurrentWrap )

			EndIf

		///////////////////////////////////////////////////////////////
		// CENTER PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'CENTER '
			If ControlType == 'ANIMATEBOX'
				CurrentCenter := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'Center' , CurrentCenter )

			EndIf

		///////////////////////////////////////////////////////////////
		// READONLY PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'READONLY '
			If ControlType == 'SPINNER'
				CurrentReadOnly := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'ReadOnly' , CurrentReadOnly )
			ElseIf ControlType == 'TEXTBOX'
				CurrentReadOnly := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'ReadOnly' , CurrentReadOnly )
			ElseIf ControlType == 'RICHEDITBOX'
				CurrentReadOnly := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'ReadOnly' , CurrentReadOnly )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'READONLY ' + CurrentReadOnly + CRLF
				endif

			ElseIf ControlType == 'EDITBOX'
				CurrentReadOnly := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'ReadOnly' , CurrentReadOnly )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'READONLY ' + CurrentReadOnly + CRLF
				endif

			ElseIf ControlType == 'RADIOGROUP'
				CurrentReadOnly := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'ReadOnly' , CurrentReadOnly )

			EndIf

		///////////////////////////////////////////////////////////////
		// READONLYFIELDS PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'READONLYFIELDS'
			If ControlType == 'BROWSE'
				CurrentReadOnlyFields := ALLTRIM(HB_USUBSTR ( Line , 16 , HMG_LEN (Line) - 15 ) )
				__MVPUT( Name + 'ReadOnlyFields' , CurrentReadOnlyFields )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'READONLYFIELDS ' + CurrentReadOnlyFields + CRLF
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// STRETCH PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'STRETCH'
			If ControlType == 'IMAGE'
				CurrentStretch := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Stretch' , CurrentStretch )

			EndIf

		///////////////////////////////////////////////////////////////
		// FLAT PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'FLAT'
			If ControlType == 'BUTTON'
				CurrentFlat := ALLTRIM(HB_USUBSTR ( Line , 6 , HMG_LEN (Line) - 5 ) )
				__MVPUT( Name + 'Flat' , CurrentFlat )
				if ALLTRIM(HMG_UPPER(CurrentFlat)) == '.T.'
					FLAT .T.
				else    
					FLAT .F.
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// HANDCURSOR PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'HANDCURSOR'
			If ControlType == 'HYPERLINK'
				CurrentHandCursor := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'HandCursor' , CurrentHandCursor )
			EndIf

		///////////////////////////////////////////////////////////////
		// AUTOPLAY PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'AUTOPLAY'
			If ControlType == 'ANIMATEBOX'
				CurrentAutoPlay := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'AutoPlay' , CurrentAutoPlay )
			EndIf

		///////////////////////////////////////////////////////////////
		// SMOOTH PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'SMOOTH'
			If ControlType == 'PROGRESSBAR'
				CurrentSmooth := ALLTRIM ( HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'Smooth' , CurrentSmooth )
			EndIf

		///////////////////////////////////////////////////////////////
		// AUTOSIZE PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'AUTOSIZE'
			If ControlType == 'LABEL'
				CurrentAutoSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'AutoSize' , CurrentAutoSize )
			ElseIf ControlType == 'HYPERLINK'
				CurrentAutoSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'AutoSize' , CurrentAutoSize )
			EndIf

		///////////////////////////////////////////////////////////////
		// PASSWORD PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'PASSWORD'
			If ControlType == 'TEXTBOX'
				CurrentPassword := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'Password' , CurrentPassword )
			EndIf

		///////////////////////////////////////////////////////////////
		// TABSTOP PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'TABSTOP'
			If ControlType == 'BUTTON'
				CurrentTabStop := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'TabStop' , CurrentTabStop )
			ElseIf ControlType == 'CHECKBOX'
				CurrentTabStop := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'TabStop' , CurrentTabStop )
			ElseIf ControlType == 'LISTBOX'
				CurrentTabStop := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'TabStop' , CurrentTabStop )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'TABSTOP ' + CurrentTabStop + CRLF
				endif

			ElseIf ControlType == 'COMBOBOX'
				CurrentTabStop := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'TabStop' , CurrentTabStop )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'TABSTOP ' + CurrentTabStop  + CRLF
				endif

			ElseIf ControlType == 'CHECKBUTTON'
				CurrentTabStop := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'TabStop' , CurrentTabStop )
			ElseIf ControlType == 'SLIDER'
				CurrentTabStop := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'TabStop' , CurrentTabStop )
			ElseIf ControlType == 'SPINNER'
				CurrentTabStop := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'TabStop' , CurrentTabStop )
			ElseIf ControlType == 'DATEPICKER'
				CurrentTabStop := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'TabStop' , CurrentTabStop )
			ElseIf ControlType == 'TEXTBOX'
				CurrentTabStop := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'TabStop' , CurrentTabStop )
			ElseIf ControlType == 'EDITBOX'
				CurrentTabStop := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'TabStop' , CurrentTabStop )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'TABSTOP ' + CurrentTabStop + CRLF
				endif

			ElseIf ControlType == 'IPADDRESS'
				CurrentTabStop := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'TabStop' , CurrentTabStop )
			ElseIf ControlType == 'RADIOGROUP'
				CurrentTabStop := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'TabStop' , CurrentTabStop )
			ElseIf ControlType == 'RICHEDITBOX'
				CurrentTabStop := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'TabStop' , CurrentTabStop )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'TABSTOP ' + CurrentTabStop + CRLF
				endif

			ElseIf ControlType == 'MONTHCALENDAR'
				CurrentTabStop := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'TabStop' , CurrentTabStop )
			EndIf

		///////////////////////////////////////////////////////////////
		// SHOWNONE PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'SHOWNONE'
			If ControlType == 'DATEPICKER'
				CurrentShowNone := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'ShowNone' , CurrentShowNone )
				if ALLTRIM(HMG_UPPER(CurrentShowNone)) == '.T.'
					SHOWNONE .T.
				else    
					SHOWNONE .F.
				endif
			EndIf

		///////////////////////////////////////////////////////////////
		// UPDOWN PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'UPDOWN'
			If ControlType == 'DATEPICKER'
				CurrentUpDown := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'UpDown' , CurrentUpDown )
				if ALLTRIM(HMG_UPPER(CurrentUpDown)) == '.T.'
					UPDOWN .T.
				else    
					UPDOWN .F.
				endif
			EndIf

		///////////////////////////////////////////////////////////////
		// RIGHTALIGN PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'RIGHTALIGN'
			If ControlType == 'DATEPICKER'
				CurrentRightAlign := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'RightAlign' , CurrentRightAlign )
				if ALLTRIM(HMG_UPPER(CurrentRightAlign)) == '.T.'
					RIGHTALIGN .T.
				else    
					RIGHTALIGN .F.
				endif
			ElseIf ControlType == 'TEXTBOX'
				CurrentRightAlign := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'RightAlign' , CurrentRightAlign )
				if ALLTRIM(HMG_UPPER(CurrentRightAlign)) == '.T.'
					RIGHTALIGN .T.
				else    
					RIGHTALIGN .F.
				endif
			ElseIf ControlType == 'LABEL'
				CurrentRightAlign := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				if ALLTRIM(HMG_UPPER(CurrentRightAlign)) == '.T.'
					RIGHTALIGN .T.
					__MVPUT( Name + 'Alignment' , 'RIGHT' )
				else    
					RIGHTALIGN .F.
					__MVPUT( Name + 'Alignment' , 'LEFT' )
				endif
			EndIf

		///////////////////////////////////////////////////////////////
		// CENTERALIGN PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'CENTERALIGN'
			If ControlType == 'LABEL'
				CurrentCenterAlign := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				if ALLTRIM(HMG_UPPER(CurrentCenterAlign)) == '.T.'
					__MVPUT( Name + 'Alignment' , 'CENTER' )
					CENTERALIGN .T.
				else    
					__MVPUT( Name + 'Alignment' , 'LEFT' )
					CENTERALIGN .F.
				endif
			EndIf

		///////////////////////////////////////////////////////////////
		// VISIBLE PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'VISIBLE'
			If ControlType == 'BUTTON'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )
			ElseIf ControlType == 'CHECKBOX'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )
			ElseIf ControlType == 'LISTBOX'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'VISIBLE ' + CurrentVisible + CRLF
				endif

			ElseIf ControlType == 'COMBOBOX'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'VISIBLE ' + CurrentVisible + CRLF
				endif

			ElseIf ControlType == 'CHECKBUTTON'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )
			ElseIf ControlType == 'SLIDER'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )
			ElseIf ControlType == 'SPINNER'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )
			ElseIf ControlType == 'IMAGE'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )
			ElseIf ControlType == 'DATEPICKER'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )
			ElseIf ControlType == 'TEXTBOX'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )
			ElseIf ControlType == 'EDITBOX'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'VISIBLE ' + CurrentVisible + CRLF
				endif

			ElseIf ControlType == 'LABEL'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )
			ElseIf ControlType == 'IPADDRESS'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )
			ElseIf ControlType == 'RADIOGROUP'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )
			ElseIf ControlType == 'PROGRESSBAR'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )
			ElseIf ControlType == 'RICHEDITBOX'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'VISIBLE ' + CurrentVisible + CRLF
				endif

			ElseIf ControlType == 'MONTHCALENDAR'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )
			ElseIf ControlType == 'HYPERLINK'
				CurrentVisible := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Visible' , CurrentVisible )
			EndIf

		///////////////////////////////////////////////////////////////
		// ALLOWEDIT PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'ALLOWEDIT'
			If ControlType == 'GRID'
				CurrentAllowEdit := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				__MVPUT( Name + 'AllowEdit' , CurrentAllowEdit )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ALLOWEDIT ' + CurrentAllowEdit + CRLF
				endif

			ElseIf ControlType == 'BROWSE'
				CurrentAllowEdit := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				__MVPUT( Name + 'AllowEdit' , CurrentAllowEdit )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ALLOWEDIT ' + CurrentAllowEdit + CRLF
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// ALLOWAPPEND PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'ALLOWAPPEND'
			If ControlType == 'BROWSE'
				CurrentAllowAppend := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'AllowAppend' , CurrentAllowAppend )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ALLOWAPPEND ' + CurrentAllowAppend + CRLF
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// ALLOWDELETE PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'ALLOWDELETE'
			If ControlType == 'BROWSE'
				CurrentAllowDelete := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'AllowDelete' , CurrentAllowDelete )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ALLOWDELETE ' + CurrentAllowDelete + CRLF
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// VIRTUAL PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'VIRTUAL'
			If ControlType == 'GRID'
				CurrentVirtual := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'Virtual' , CurrentVirtual )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'VIRTUAL ' + CurrentVirtual + CRLF
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// LINES PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'NOLINES'
			If ControlType == 'GRID'
				CurrentLines := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'NOLINES ' + CurrentLines + CRLF

					if ALLTRIM(HMG_UPPER(CurrentLines)) == '.T.'
						__MVPUT( Name + 'Lines' , '.F.' )
					else
						__MVPUT( Name + 'Lines' , '.T.' )
					endif

				else

					if ALLTRIM(HMG_UPPER(CurrentLines)) == '.T.'
						NOLINES .T.
						__MVPUT( Name + 'Lines' , '.F.' )
					else
						NOLINES .F.
						__MVPUT( Name + 'Lines' , '.T.' )
					endif

				endif

			ElseIf ControlType == 'BROWSE'
				CurrentLines := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'NOLINES ' + CurrentLines + CRLF

					if ALLTRIM(HMG_UPPER(CurrentLines)) == '.T.'
						__MVPUT( Name + 'Lines' , '.F.' )
					else
						__MVPUT( Name + 'Lines' , '.T.' )
					endif

				else

					if ALLTRIM(HMG_UPPER(CurrentLines)) == '.T.'
						NOLINES .T.
						__MVPUT( Name + 'Lines' , '.F.' )
					else
						NOLINES .F.
						__MVPUT( Name + 'Lines' , '.T.' )
					endif

				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// TRANSPARENT PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'TRANSPARENT'
			If ControlType == 'BUTTON'
				CurrentTransparent := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'Transparent' , CurrentTransparent )
			ElseIf ControlType == 'CHECKBOX'
				CurrentTransparent := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'Transparent' , CurrentTransparent )
			ElseIf ControlType == 'LABEL'
				CurrentTransparent := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'Transparent' , CurrentTransparent )
			ElseIf ControlType == 'RADIOGROUP'
				CurrentTransparent := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'Transparent' , CurrentTransparent )
			ElseIf ControlType == 'FRAME'
				CurrentTransparent := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'Transparent' , CurrentTransparent )
				if ALLTRIM(HMG_UPPER(CurrentTransparent)) == '.F.'
					OPAQUE .T.
				endif
			ElseIf ControlType == 'ANIMATEBOX'
				CurrentTransparent := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'Transparent' , CurrentTransparent )
			EndIf

		///////////////////////////////////////////////////////////////
		// OPAQUE PROPERTY
		///////////////////////////////////////////////////////////////
		ElseIf	HMG_UPPER (Line) = 'OPAQUE'
			If ControlType == 'FRAME'
				CurrentOpaque := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				if ALLTRIM(HMG_UPPER(CurrentOpaque)) == '.T.'
					__MVPUT( Name + 'Transparent' , '.F.' )
					OPAQUE .T.
				else
					__MVPUT( Name + 'Transparent' , '.T.' )
					OPAQUE .F.
				endif
			EndIf

		///////////////////////////////////////////////////////////////
		// FONTSIZE PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'FONTSIZE'

			If ControlType == 'BUTTON'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				FONTSIZE VAL ( CurrentFontSize )

			ElseIf ControlType == 'CHECKBOX'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				FONTSIZE VAL ( CurrentFontSize )

			ElseIf ControlType == 'LISTBOX'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTSIZE ' + CurrentFontSize + CRLF
				else
					FONTSIZE VAL ( CurrentFontSize )
				endif

			ElseIf ControlType == 'COMBOBOX'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTSIZE ' + CurrentFontSize + CRLF
				else
					FONTSIZE VAL ( CurrentFontSize )
				endif

			ElseIf ControlType == 'CHECKBUTTON'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				FONTSIZE VAL ( CurrentFontSize )

			ElseIf ControlType == 'GRID'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTSIZE ' + CurrentFontSize + CRLF
				else
					FONTSIZE VAL ( CurrentFontSize )
				endif

			ElseIf	ControlType == 'SPINNER'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				FONTSIZE VAL ( CurrentFontSize )

			ElseIf	ControlType == 'DATEPICKER'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				FONTSIZE VAL ( CurrentFontSize )

			ElseIf	ControlType == 'TEXTBOX'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				FONTSIZE VAL ( CurrentFontSize )

			ElseIf	ControlType == 'EDITBOX'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTSIZE ' + CurrentFontSize + CRLF
				else
					FONTSIZE VAL ( CurrentFontSize )
				endif

			ElseIf	ControlType == 'LABEL'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				FONTSIZE VAL ( CurrentFontSize )

			ElseIf	ControlType == 'BROWSE'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTSIZE ' + CurrentFontSize + CRLF
				else
					FONTSIZE VAL ( CurrentFontSize )
				endif

			ElseIf	ControlType == 'RADIOGROUP'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) ) 

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				CurrentFontSize := VAL ( CurrentFontSize )

			ElseIf	ControlType == 'FRAME'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				FONTSIZE VAL ( CurrentFontSize )

			ElseIf	ControlType == 'HYPERLINK'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				FONTSIZE VAL ( CurrentFontSize )

			ElseIf	ControlType == 'MONTHCALENDAR'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				FONTSIZE VAL ( CurrentFontSize )

			ElseIf	ControlType == 'RICHEDITBOX'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTSIZE ' + CurrentFontSize + CRLF
				else
					FONTSIZE VAL ( CurrentFontSize )
				endif

			ElseIf	ControlType == 'IPADDRESS'

				CurrentFontSize := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )

				__MVPUT( Name + 'FontSize' , CurrentFontSize )

				FONTSIZE VAL ( CurrentFontSize )

			EndIf

		///////////////////////////////////////////////////////////////
		// SPACING PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'SPACING'

			If	ControlType == 'RADIOGROUP'
				CurrentSpacing := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) ) 
				__MVPUT( Name + 'Spacing' , CurrentSpacing )
				CurrentSpacing := VAL ( CurrentSpacing )
			EndIf

		///////////////////////////////////////////////////////////////
		// TOOLTIP PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'TOOLTIP'

			If ControlType == 'BUTTON'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				TOOLTIP CurrentToolTip

			ElseIf	ControlType == 'CHECKBOX'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				TOOLTIP CurrentToolTip

			ElseIf	ControlType == 'LISTBOX'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'TOOLTIP ' + '"' + CurrentToolTip + '"' + CRLF
				else
					TOOLTIP CurrentToolTip
				endif

			ElseIf	ControlType == 'COMBOBOX'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'TOOLTIP ' + '"' + CurrentToolTip + '"' + CRLF
				else
					TOOLTIP CurrentToolTip
				endif

			ElseIf	ControlType == 'CHECKBUTTON'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				TOOLTIP CurrentToolTip

			ElseIf	ControlType == 'GRID'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'TOOLTIP ' + '"' + CurrentToolTip + '"' + CRLF
				else
					TOOLTIP CurrentToolTip
				endif

			ElseIf	ControlType == 'SLIDER'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				TOOLTIP CurrentToolTip

			ElseIf	ControlType == 'SPINNER'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				TOOLTIP CurrentToolTip

			ElseIf	ControlType == 'DATEPICKER'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				TOOLTIP CurrentToolTip

			ElseIf	ControlType == 'TEXTBOX'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				TOOLTIP CurrentToolTip

			ElseIf	ControlType == 'EDITBOX'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'TOOLTIP ' + '"' + CurrentToolTip + '"' + CRLF
				else
					TOOLTIP CurrentToolTip
				endif

			ElseIf	ControlType == 'LABEL'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				TOOLTIP CurrentToolTip

			ElseIf	ControlType == 'BROWSE'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'TOOLTIP ' + '"' + CurrentToolTip + '"' + CRLF
				else
					TOOLTIP CurrentToolTip
				endif

			ElseIf	ControlType == 'RADIOGROUP'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				TOOLTIP CurrentToolTip

			ElseIf	ControlType == 'HYPERLINK'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				TOOLTIP CurrentToolTip

			ElseIf	ControlType == 'MONTHCALENDAR'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				TOOLTIP CurrentToolTip

			ElseIf	ControlType == 'RICHEDITBOX'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'TOOLTIP ' + '"' + CurrentToolTip + '"' + CRLF
				else
					TOOLTIP CurrentToolTip
				endif

			ElseIf	ControlType == 'PROGRESSBAR'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				TOOLTIP CurrentToolTip

			ElseIf	ControlType == 'IPADDRESS'

				CurrentToolTip := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if	HB_ULEFT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentToolTip , 1 ) == "'" 

					CurrentToolTip := HB_URIGHT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentToolTip , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentToolTip , 1 ) == "'"

					CurrentToolTip := HB_ULEFT ( CurrentToolTip , HMG_LEN( CurrentToolTip ) - 1 )

				EndIf

				__MVPUT( Name + 'ToolTip' , CurrentToolTip )

				TOOLTIP CurrentToolTip

			EndIf


		///////////////////////////////////////////////////////////////
		// ONDROPDOWN EVENT
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ONDROPDOWN'

			If ControlType == 'COMBOBOX'
				CurrentOnDropDown := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'OnDropDown' , CurrentOnDropDown )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONDROPDOWN ' + CurrentOnDropDown + CRLF
				endif
			EndIf

		///////////////////////////////////////////////////////////////
		// ONCLOSEUP EVENT
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ONCLOSEUP'

			If ControlType == 'COMBOBOX'
				CurrentOnCloseUp := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				__MVPUT( Name + 'OnCloseUp' , CurrentOnCloseUp )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONCLOSEUP ' + CurrentOnCloseUp + CRLF
				endif
			EndIf


		///////////////////////////////////////////////////////////////
		// ONENTER EVENT
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ONENTER'
			If ControlType == 'COMBOBOX'
				CurrentOnEnter := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'OnEnter' , CurrentOnEnter )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONENTER ' + CurrentOnEnter + CRLF
				endif

			ElseIf ControlType == 'DATEPICKER'
				CurrentOnEnter := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'OnEnter' , CurrentOnEnter )
			ElseIf ControlType == 'TEXTBOX'
				CurrentOnEnter := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )
				__MVPUT( Name + 'OnEnter' , CurrentOnEnter )
			EndIf

		///////////////////////////////////////////////////////////////
		// ONDISPLAYCHANGE EVENT
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ONDISPLAYCHANGE'
			If ControlType == 'COMBOBOX'
				CurrentOnDisplayChange := ALLTRIM(HB_USUBSTR ( Line , 17 , HMG_LEN (Line) - 16 ) )
				__MVPUT( Name + 'OnDisplayChange' , CurrentOnDisplayChange )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONDISPLAYCHANGE ' + CurrentOnDisplayChange + CRLF
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// ONCHANGE EVENT
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ONCHANGE'

			If ControlType == 'CHECKBOX'

				CurrentOnChange := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'OnChange' , CurrentOnChange )

			ElseIf	ControlType == 'LISTBOX'

				CurrentOnChange := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'OnChange' , CurrentOnChange )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONCHANGE ' + CurrentOnChange + CRLF
				endif

			ElseIf	ControlType == 'COMBOBOX'

				CurrentOnChange := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'OnChange' , CurrentOnChange )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONCHANGE ' + CurrentOnChange + CRLF
				endif

			ElseIf	ControlType == 'CHECKBUTTON'

				CurrentOnChange := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'OnChange' , CurrentOnChange )

			ElseIf	ControlType == 'GRID'

				CurrentOnChange := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'OnChange' , CurrentOnChange )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONCHANGE ' + CurrentOnChange + CRLF
				endif

			ElseIf	ControlType == 'SLIDER'

				CurrentOnChange := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'OnChange' , CurrentOnChange )

			ElseIf	ControlType == 'SPINNER'

				CurrentOnChange := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'OnChange' , CurrentOnChange )

			ElseIf	ControlType == 'DATEPICKER'

				CurrentOnChange := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'OnChange' , CurrentOnChange )

			ElseIf	ControlType == 'TEXTBOX'

				CurrentOnChange := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'OnChange' , CurrentOnChange )

			ElseIf	ControlType == 'EDITBOX'

				CurrentOnChange := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'OnChange' , CurrentOnChange )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONCHANGE ' + CurrentOnChange + CRLF
				endif

			ElseIf	ControlType == 'BROWSE'

				CurrentOnChange := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'OnChange' , CurrentOnChange )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONCHANGE ' + CurrentOnChange + CRLF
				endif

			ElseIf	ControlType == 'RADIOGROUP'

				CurrentOnChange := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'OnChange' , CurrentOnChange )

			ElseIf	ControlType == 'MONTHCALENDAR'

				CurrentOnChange := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'OnChange' , CurrentOnChange )

			ElseIf	ControlType == 'RICHEDITBOX'

				CurrentOnChange := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'OnChange' , CurrentOnChange )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONCHANGE ' + CurrentOnChange + CRLF
				endif

			ElseIf	ControlType == 'IPADDRESS'

				CurrentOnChange := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'OnChange' , CurrentOnChange )

			EndIf

		///////////////////////////////////////////////////////////////
		// ONGOTFOCUS EVENT
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ONGOTFOCUS'

			If	ControlType == 'BUTTON'
				CurrentOnGotFocus := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'OnGotFocus' , CurrentOnGotFocus )

			ElseIf	ControlType == 'CHECKBOX'
				CurrentOnGotFocus := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'OnGotFocus' , CurrentOnGotFocus )

			ElseIf	ControlType == 'LISTBOX'
				CurrentOnGotFocus := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'OnGotFocus' , CurrentOnGotFocus )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONGOTFOCUS ' + CurrentOnGotFocus + CRLF
				endif

			ElseIf	ControlType == 'COMBOBOX'
				CurrentOnGotFocus := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'OnGotFocus' , CurrentOnGotFocus )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONGOTFOCUS ' + CurrentOnGotFocus + CRLF
				endif

			ElseIf	ControlType == 'CHECKBUTTON'
				CurrentOnGotFocus := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'OnGotFocus' , CurrentOnGotFocus )

			ElseIf	ControlType == 'GRID'
				CurrentOnGotFocus := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'OnGotFocus' , CurrentOnGotFocus )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONGOTFOCUS ' + CurrentOnGotFocus + CRLF
				endif

			ElseIf	ControlType == 'SPINNER'
				CurrentOnGotFocus := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'OnGotFocus' , CurrentOnGotFocus )

			ElseIf	ControlType == 'DATEPICKER'
				CurrentOnGotFocus := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'OnGotFocus' , CurrentOnGotFocus )

			ElseIf	ControlType == 'TEXTBOX'
				CurrentOnGotFocus := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'OnGotFocus' , CurrentOnGotFocus )

			ElseIf	ControlType == 'EDITBOX'
				CurrentOnGotFocus := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'OnGotFocus' , CurrentOnGotFocus )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONGOTFOCUS ' + CurrentOnGotFocus + CRLF
				endif

			ElseIf	ControlType == 'BROWSE'
				CurrentOnGotFocus := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'OnGotFocus' , CurrentOnGotFocus )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONGOTFOCUS ' + CurrentOnGotFocus + CRLF
				endif

			ElseIf	ControlType == 'RICHEDITBOX'
				CurrentOnGotFocus := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'OnGotFocus' , CurrentOnGotFocus )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONGOTFOCUS ' + CurrentOnGotFocus + CRLF
				endif

			ElseIf	ControlType == 'IPADDRESS'
				CurrentOnGotFocus := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'OnGotFocus' , CurrentOnGotFocus )

			EndIf





		///////////////////////////////////////////////////////////////
		// ONSAVE EVENT
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ONSAVE'

			If	ControlType == 'GRID'
				CurrentOnSave := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'OnSave' , CurrentOnSave )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONSAVE ' + CurrentOnSave + CRLF
				endif

			EndIf


		///////////////////////////////////////////////////////////////
		// ONDBLCLICK EVENT
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ONDBLCLICK'

			If	ControlType == 'LISTBOX'
				CurrentOnDblClick := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'OnDblClick' , CurrentOnDblClick )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONDBLCLICK ' + CurrentOnDblClick + CRLF
				endif

			ElseIf	ControlType == 'GRID'
				CurrentOnDblClick := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'OnDblClick' , CurrentOnDblClick )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONDBLCLICK ' + CurrentOnDblClick + CRLF
				endif

			ElseIf	ControlType == 'BROWSE'
				CurrentOnDblClick := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'OnDblClick' , CurrentOnDblClick )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONDBLCLICK ' + CurrentOnDblClick + CRLF
				endif

			EndIf
		///////////////////////////////////////////////////////////////
		// ONHEADCLICK EVENT
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ONHEADCLICK'

			If	ControlType == 'GRID'
				CurrentOnHeadClick := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'OnHeadClick' , CurrentOnHeadClick )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONHEADCLICK ' + CurrentOnHeadClick + CRLF
				endif

			ElseIf	ControlType == 'BROWSE'
				CurrentOnHeadClick := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'OnHeadClick' , CurrentOnHeadClick )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONHEADCLICK ' + CurrentOnHeadClick + CRLF
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// ONQUERYDATA EVENT
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ONQUERYDATA'

			If	ControlType == 'GRID'
				CurrentOnQueryData := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'OnQueryData' , CurrentOnQueryData )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONQUERYDATA ' + CurrentOnQueryData + CRLF
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// ONLOSTFOCUS EVENT
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'ONLOSTFOCUS'

			If	ControlType == 'BUTTON'
				CurrentOnLostFocus := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'OnLostFocus' , CurrentOnLostFocus )

			ElseIf	ControlType == 'CHECKBOX'
				CurrentOnLostFocus := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'OnLostFocus' , CurrentOnLostFocus )

			ElseIf	ControlType == 'LISTBOX'
				CurrentOnLostFocus := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'OnLostFocus' , CurrentOnLostFocus )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONLOSTFOCUS ' + CurrentOnLostFocus + CRLF
				endif

			ElseIf	ControlType == 'COMBOBOX'
				CurrentOnLostFocus := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'OnLostFocus' , CurrentOnLostFocus )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONLOSTFOCUS ' + CurrentOnLostFocus + CRLF
				endif

			ElseIf	ControlType == 'CHECKBUTTON'
				CurrentOnLostFocus := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'OnLostFocus' , CurrentOnLostFocus )

			ElseIf	ControlType == 'GRID'
				CurrentOnLostFocus := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'OnLostFocus' , CurrentOnLostFocus )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONLOSTFOCUS ' + CurrentOnLostFocus + CRLF
				endif

			ElseIf	ControlType == 'SPINNER'
				CurrentOnLostFocus := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'OnLostFocus' , CurrentOnLostFocus )

			ElseIf	ControlType == 'DATEPICKER'
				CurrentOnLostFocus := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'OnLostFocus' , CurrentOnLostFocus )

			ElseIf	ControlType == 'TEXTBOX'
				CurrentOnLostFocus := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'OnLostFocus' , CurrentOnLostFocus )

			ElseIf	ControlType == 'EDITBOX'
				CurrentOnLostFocus := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'OnLostFocus' , CurrentOnLostFocus )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONLOSTFOCUS ' + CurrentOnLostFocus + CRLF
				endif

			ElseIf	ControlType == 'BROWSE'
				CurrentOnLostFocus := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'OnLostFocus' , CurrentOnLostFocus )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONLOSTFOCUS ' + CurrentOnLostFocus + CRLF
				endif

			ElseIf	ControlType == 'RICHEDITBOX'
				CurrentOnLostFocus := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'OnLostFocus' , CurrentOnLostFocus )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'ONLOSTFOCUS ' + CurrentOnLostFocus + CRLF
				endif

			ElseIf	ControlType == 'IPADDRESS'
				CurrentOnLostFocus := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'OnLostFocus' , CurrentOnLostFocus )

			EndIf

		///////////////////////////////////////////////////////////////
		// INPUTMASK PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'INPUTMASK'

			If	ControlType == 'TEXTBOX'

				CurrentInputMask := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )

				if	HB_ULEFT ( CurrentInputMask , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentInputMask , 1 ) == "'" 

					CurrentInputMask := HB_URIGHT ( CurrentInputMask , HMG_LEN( CurrentInputMask ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentInputMask , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentInputMask , 1 ) == "'"

					CurrentInputMask := HB_ULEFT ( CurrentInputMask , HMG_LEN( CurrentInputMask ) - 1 )

				EndIf

				if ALLTRIM ( HMG_UPPER (CurrentInputMask) ) == 'NIL'
					CurrentInputMask := ''
				endif

				__MVPUT( Name + 'InputMask' , CurrentInputMask )

			EndIf

			If	ControlType == 'BROWSE'

				CurrentInputMask := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				__MVPUT( Name + 'InputMask' , CurrentInputMask )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'INPUTMASK ' + CurrentInputMask + CRLF
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// FORMAT PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'FORMAT'

			If	ControlType == 'TEXTBOX'

				CurrentFormat := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )

				if	HB_ULEFT ( CurrentFormat , 1 ) == '"' ;
					.or. ;
					HB_ULEFT ( CurrentFormat , 1 ) == "'" 

					CurrentFormat := HB_URIGHT ( CurrentFormat , HMG_LEN( CurrentFormat ) - 1 )

				EndIf

				if	HB_URIGHT ( CurrentFormat , 1 ) == '"' ;
					.or. ;
					HB_URIGHT ( CurrentFormat , 1 ) == "'"

					CurrentFormat := HB_ULEFT ( CurrentFormat , HMG_LEN( CurrentFormat ) - 1 )

				EndIf

				if ALLTRIM ( HMG_UPPER (CurrentFormat) ) == 'NIL'
					CurrentFormat := ''
				endif

				__MVPUT( Name + 'Format' , CurrentFormat )

			EndIf

			If	ControlType == 'BROWSE'
				CurrentFormat := ALLTRIM(HB_USUBSTR ( Line , 8 , HMG_LEN (Line) - 7 ) )
				__MVPUT( Name + 'Format' , CurrentFormat )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FORMAT ' + CurrentFormat + CRLF
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// NUMERIC PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'NUMERIC'

			If	ControlType == 'TEXTBOX'

				CurrentNumeric := ALLTRIM(HB_USUBSTR ( Line , 9 , HMG_LEN (Line) - 8 ) )

				if ALLTRIM(HMG_UPPER(CurrentNumeric)) == '.T.'
					__MVPUT( Name + 'DataType' , 'NUMERIC' )
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// SORT PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'SORT'

			If ControlType == 'LISTBOX'
				CurrentSort := ALLTRIM(HB_USUBSTR ( Line , 6 , HMG_LEN (Line) - 5 ) )
				__MVPUT( Name + 'Sort' , CurrentSort )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'SORT ' + CurrentSort + CRLF
				endif

			ElseIf ControlType == 'COMBOBOX'
				CurrentSort := ALLTRIM(HB_USUBSTR ( Line , 6 , HMG_LEN (Line) - 5 ) )
				__MVPUT( Name + 'Sort' , CurrentSort )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'SORT ' + CurrentSort + CRLF
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// MULTISELECT PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'MULTISELECT'

			If ControlType == 'LISTBOX'
				CurrentMultiSelect := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'MultiSelect' , CurrentMultiSelect )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'MULTISELECT ' + CurrentMultiSelect + CRLF
				endif

			ElseIf ControlType == 'GRID'
				CurrentMultiSelect := ALLTRIM(HB_USUBSTR ( Line , 13 , HMG_LEN (Line) - 12 ) )
				__MVPUT( Name + 'MultiSelect' , CurrentMultiSelect )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'MULTISELECT ' + CurrentMultiSelect + CRLF
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// CELLNAVIGATION PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'CELLNAVIGATION'

			If ControlType == 'GRID'
				CurrentCellNavigation := ALLTRIM(HB_USUBSTR ( Line , 16 , HMG_LEN (Line) - 15 ) )
				__MVPUT( Name + 'CellNavigation' , CurrentCellNavigation )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'CELLNAVIGATION ' + CurrentCellNavigation + CRLF
				endif

			EndIf



		///////////////////////////////////////////////////////////////
		// MULTILINE PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'MULTILINE'

			If ControlType == 'BUTTON'

				CurrentMultiLine := ALLTRIM(HB_USUBSTR ( Line , 11 , HMG_LEN (Line) - 10 ) )
				__MVPUT( Name + 'MultiLine' , CurrentMultiLine )
				if ALLTRIM(HMG_UPPER(CurrentMultiLine)) == '.T.'
					MULTILINE .T.
				else
					MULTILINE .F.
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// FONTBOLD PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'FONTBOLD'

			If ControlType == 'BUTTON'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )
				if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
					FONTBOLD .T.
				else
					FONTBOLD .F.
				endif

			ElseIf ControlType == 'CHECKBOX'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )
				if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
					FONTBOLD .T.
				else
					FONTBOLD .F.
				endif

			ElseIf ControlType == 'LISTBOX'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTBOLD ' + CurrentFontBold + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
						FONTBOLD .T.
					else
						FONTBOLD .F.
					endif

				endif

			ElseIf ControlType == 'COMBOBOX'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTBOLD ' + CurrentFontBold + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
						FONTBOLD .T.
					else
						FONTBOLD .F.
					endif

				endif

			ElseIf ControlType == 'CHECKBUTTON'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )
				if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
					FONTBOLD .T.
				else
					FONTBOLD .F.
				endif

			ElseIf ControlType == 'GRID'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTBOLD ' + CurrentFontBold + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
						FONTBOLD .T.
					else
						FONTBOLD .F.
					endif

				endif

			ElseIf	ControlType == 'SPINNER'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )
				if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
					FONTBOLD .T.
				else
					FONTBOLD .F.
				endif

			ElseIf	ControlType == 'DATEPICKER'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )
				if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
					FONTBOLD .T.
				else
					FONTBOLD .F.
				endif

			ElseIf	ControlType == 'TEXTBOX'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )
				if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
					FONTBOLD .T.
				else
					FONTBOLD .F.
				endif

			ElseIf	ControlType == 'EDITBOX'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTBOLD ' + CurrentFontBold + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
						FONTBOLD .T.
					else
						FONTBOLD .F.
					endif

				endif

			ElseIf	ControlType == 'LABEL'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )
				if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
					FONTBOLD .T.
				else
					FONTBOLD .F.
				endif

			ElseIf	ControlType == 'BROWSE'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTBOLD ' + CurrentFontBold + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
						FONTBOLD .T.
					else
						FONTBOLD .F.
					endif

				endif

			ElseIf	ControlType == 'RADIOGROUP'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )
				if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
					FONTBOLD .T.
				else
					FONTBOLD .F.
				endif

			ElseIf	ControlType == 'FRAME'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )
				if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
					FONTBOLD .T.
				else
					FONTBOLD .F.
				endif

			ElseIf	ControlType == 'HYPERLINK'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )
				if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
					FONTBOLD .T.
				else
					FONTBOLD .F.
				endif

			ElseIf	ControlType == 'MONTHCALENDAR'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )
				if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
					FONTBOLD .T.
				else
					FONTBOLD .F.
				endif

			ElseIf	ControlType == 'RICHEDITBOX'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTBOLD ' + CurrentFontBold + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
						FONTBOLD .T.
					else
						FONTBOLD .F.
					endif

				endif

			ElseIf	ControlType == 'IPADDRESS'

				CurrentFontBold := ALLTRIM(HB_USUBSTR ( Line , 10 , HMG_LEN (Line) - 9 ) )
				__MVPUT( Name + 'FontBold' , CurrentFontBold )
				if ALLTRIM(HMG_UPPER(CurrentFontBold)) == '.T.'
					FONTBOLD .T.
				else
					FONTBOLD .F.
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// FONTITALIC PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'FONTITALIC'

			If ControlType == 'BUTTON'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )
				if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
					FONTITALIC .T.
				else
					FONTITALIC .F.
				endif

			ElseIf ControlType == 'CHECKBOX'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )
				if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
					FONTITALIC .T.
				else
					FONTITALIC .F.
				endif

			ElseIf ControlType == 'LISTBOX'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTITALIC ' + CurrentFontItalic + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
						FONTITALIC .T.
					else
						FONTITALIC .F.
					endif
				endif

			ElseIf ControlType == 'COMBOBOX'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTITALIC ' + CurrentFontItalic + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
						FONTITALIC .T.
					else
						FONTITALIC .F.
					endif
				endif

			ElseIf ControlType == 'CHECKBUTTON'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )
				if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
					FONTITALIC .T.
				else
					FONTITALIC .F.
				endif

			ElseIf ControlType == 'GRID'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTITALIC ' + CurrentFontItalic + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
						FONTITALIC .T.
					else
						FONTITALIC .F.
					endif
				endif

			ElseIf	ControlType == 'SPINNER'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )
				if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
					FONTITALIC .T.
				else
					FONTITALIC .F.
				endif

			ElseIf	ControlType == 'DATEPICKER'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )
				if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
					FONTITALIC .T.
				else
					FONTITALIC .F.
				endif

			ElseIf	ControlType == 'TEXTBOX'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )
				if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
					FONTITALIC .T.
				else
					FONTITALIC .F.
				endif

			ElseIf	ControlType == 'EDITBOX'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTITALIC ' + CurrentFontItalic + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
						FONTITALIC .T.
					else
						FONTITALIC .F.
					endif
				endif

			ElseIf	ControlType == 'LABEL'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )
				if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
					FONTITALIC .T.
				else
					FONTITALIC .F.
				endif

			ElseIf	ControlType == 'BROWSE'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTITALIC ' + CurrentFontItalic + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
						FONTITALIC .T.
					else
						FONTITALIC .F.
					endif
				endif

			ElseIf	ControlType == 'RADIOGROUP'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )
				if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
					FONTITALIC .T.
				else
					FONTITALIC .F.
				endif

			ElseIf	ControlType == 'FRAME'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )
				if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
					FONTITALIC .T.
				else
					FONTITALIC .F.
				endif

			ElseIf	ControlType == 'HYPERLINK'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )
				if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
					FONTITALIC .T.
				else
					FONTITALIC .F.
				endif

			ElseIf	ControlType == 'MONTHCALENDAR'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )
				if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
					FONTITALIC .T.
				else
					FONTITALIC .F.
				endif

			ElseIf	ControlType == 'RICHEDITBOX'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTITALIC ' + CurrentFontItalic + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
						FONTITALIC .T.
					else
						FONTITALIC .F.
					endif
				endif

			ElseIf	ControlType == 'IPADDRESS'

				CurrentFontItalic := ALLTRIM(HB_USUBSTR ( Line , 12 , HMG_LEN (Line) - 11 ) )
				__MVPUT( Name + 'FontItalic' , CurrentFontItalic )
				if ALLTRIM(HMG_UPPER(CurrentFontItalic)) == '.T.'
					FONTITALIC .T.
				else
					FONTITALIC .F.
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// FONTSTRIKEOUT PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'FONTSTRIKEOUT'

			If ControlType == 'BUTTON'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )
				if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
					FONTSTRIKEOUT .T.
				else
					FONTSTRIKEOUT .F.
				endif

			ElseIf ControlType == 'CHECKBOX'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )
				if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
					FONTSTRIKEOUT .T.
				else
					FONTSTRIKEOUT .F.
				endif

			ElseIf ControlType == 'LISTBOX'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTSTRIKEOUT ' + CurrentFontStrikeout + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
						FONTSTRIKEOUT .T.
					else
						FONTSTRIKEOUT .F.
					endif
				endif

			ElseIf ControlType == 'COMBOBOX'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTSTRIKEOUT ' + CurrentFontStrikeout + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
						FONTSTRIKEOUT .T.
					else
						FONTSTRIKEOUT .F.
					endif
				endif

			ElseIf ControlType == 'CHECKBUTTON'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )
				if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
					FONTSTRIKEOUT .T.
				else
					FONTSTRIKEOUT .F.
				endif

			ElseIf ControlType == 'GRID'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTSTRIKEOUT ' + CurrentFontStrikeout + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
						FONTSTRIKEOUT .T.
					else
						FONTSTRIKEOUT .F.
					endif
				endif

			ElseIf	ControlType == 'SPINNER'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )
				if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
					FONTSTRIKEOUT .T.
				else
					FONTSTRIKEOUT .F.
				endif

			ElseIf	ControlType == 'DATEPICKER'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )
				if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
					FONTSTRIKEOUT .T.
				else
					FONTSTRIKEOUT .F.
				endif

			ElseIf	ControlType == 'TEXTBOX'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )
				if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
					FONTSTRIKEOUT .T.
				else
					FONTSTRIKEOUT .F.
				endif

			ElseIf	ControlType == 'EDITBOX'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTSTRIKEOUT ' + CurrentFontStrikeout + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
						FONTSTRIKEOUT .T.
					else
						FONTSTRIKEOUT .F.
					endif
				endif

			ElseIf	ControlType == 'LABEL'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )
				if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
					FONTSTRIKEOUT .T.
				else
					FONTSTRIKEOUT .F.
				endif

			ElseIf	ControlType == 'BROWSE'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTSTRIKEOUT ' + CurrentFontStrikeout + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
						FONTSTRIKEOUT .T.
					else
						FONTSTRIKEOUT .F.
					endif
				endif

			ElseIf	ControlType == 'RADIOGROUP'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )
				if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
					FONTSTRIKEOUT .T.
				else
					FONTSTRIKEOUT .F.
				endif

			ElseIf	ControlType == 'FRAME'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )
				if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
					FONTSTRIKEOUT .T.
				else
					FONTSTRIKEOUT .F.
				endif

			ElseIf	ControlType == 'HYPERLINK'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )
				if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
					FONTSTRIKEOUT .T.
				else
					FONTSTRIKEOUT .F.
				endif

			ElseIf	ControlType == 'MONTHCALENDAR'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )
				if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
					FONTSTRIKEOUT .T.
				else
					FONTSTRIKEOUT .F.
				endif

			ElseIf	ControlType == 'RICHEDITBOX'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTSTRIKEOUT ' + CurrentFontStrikeout + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
						FONTSTRIKEOUT .T.
					else
						FONTSTRIKEOUT .F.
					endif
				endif

			ElseIf	ControlType == 'IPADDRESS'

				CurrentFontStrikeout := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontStrikeout' , CurrentFontStrikeout )
				if ALLTRIM(HMG_UPPER(CurrentFontStrikeout)) == '.T.'
					FONTSTRIKEOUT .T.
				else
					FONTSTRIKEOUT .F.
				endif

			EndIf

		///////////////////////////////////////////////////////////////
		// FONTUNDERLINE PROPERTY
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'FONTUNDERLINE'

			If ControlType == 'BUTTON'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )
				if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
					FONTUNDERLINE .T.
				else
					FONTUNDERLINE .F.
				endif

			ElseIf ControlType == 'CHECKBOX'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )
				if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
					FONTUNDERLINE .T.
				else
					FONTUNDERLINE .F.
				endif

			ElseIf ControlType == 'LISTBOX'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTUNDERLINE ' + CurrentFontUnderLine + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
						FONTUNDERLINE .T.
					else
						FONTUNDERLINE .F.
					endif

				endif

			ElseIf ControlType == 'COMBOBOX'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTUNDERLINE ' + CurrentFontUnderLine + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
						FONTUNDERLINE .T.
					else
						FONTUNDERLINE .F.
					endif

				endif

			ElseIf ControlType == 'CHECKBUTTON'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )

				if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
					FONTUNDERLINE .T.
				else
					FONTUNDERLINE .F.
				endif

			ElseIf ControlType == 'GRID'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTUNDERLINE ' + CurrentFontUnderLine + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
						FONTUNDERLINE .T.
					else
						FONTUNDERLINE .F.
					endif

				endif

			ElseIf	ControlType == 'SPINNER'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )
				if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
					FONTUNDERLINE .T.
				else
					FONTUNDERLINE .F.
				endif

			ElseIf	ControlType == 'DATEPICKER'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )
				if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
					FONTUNDERLINE .T.
				else
					FONTUNDERLINE .F.
				endif

			ElseIf	ControlType == 'TEXTBOX'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )
				if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
					FONTUNDERLINE .T.
				else
					FONTUNDERLINE .F.
				endif

			ElseIf	ControlType == 'EDITBOX'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTUNDERLINE ' + CurrentFontUnderLine + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
						FONTUNDERLINE .T.
					else
						FONTUNDERLINE .F.
					endif

				endif

			ElseIf	ControlType == 'LABEL'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )
				if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
					FONTUNDERLINE .T.
				else
					FONTUNDERLINE .F.
				endif

			ElseIf	ControlType == 'BROWSE'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTUNDERLINE ' + CurrentFontUnderLine + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
						FONTUNDERLINE .T.
					else
						FONTUNDERLINE .F.
					endif

				endif

			ElseIf	ControlType == 'RADIOGROUP'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )
				if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
					FONTUNDERLINE .T.
				else
					FONTUNDERLINE .F.
				endif

			ElseIf	ControlType == 'FRAME'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )
				if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
					FONTUNDERLINE .T.
				else
					FONTUNDERLINE .F.
				endif

			ElseIf	ControlType == 'HYPERLINK'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )
				if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
					FONTUNDERLINE .T.
				else
					FONTUNDERLINE .F.
				endif

			ElseIf	ControlType == 'MONTHCALENDAR'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )
				if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
					FONTUNDERLINE .T.
				else
					FONTUNDERLINE .F.
				endif

			ElseIf	ControlType == 'RICHEDITBOX'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )

				if _hmgide_SplitBoxProcessing == .T.
					_hmgide_CurrentSplitBox := _hmgide_CurrentSplitBox + Space(12) + 'FONTUNDERLINE ' + CurrentFontUnderLine + CRLF
				else

					if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
						FONTUNDERLINE .T.
					else
						FONTUNDERLINE .F.
					endif

				endif

			ElseIf	ControlType == 'IPADDRESS'

				CurrentFontUnderLine := ALLTRIM(HB_USUBSTR ( Line , 15 , HMG_LEN (Line) - 14 ) )
				__MVPUT( Name + 'FontUnderLine' , CurrentFontUnderLine )
				if ALLTRIM(HMG_UPPER(CurrentFontUnderLine)) == '.T.'
					FONTUNDERLINE .T.
				else
					FONTUNDERLINE .F.
				endif

			EndIf


		///////////////////////////////////////////////////////////////
		///////////////////////////////////////////////////////////////
		///////////////////////////////////////////////////////////////

		///////////////////////////////////////////////////////////////
		// DEFINE WINDOW COMMAND
		///////////////////////////////////////////////////////////////

		ElseIf	HMG_UPPER (Line) = 'DEFINE WINDOW TEMPLATE'

			* Determine AT

			a := 27
			b := HB_UAT ( "," , HMG_UPPER (Line) )
			c := HB_UAT ( " WIDTH " , HMG_UPPER (Line) )			

			WinRow := HB_USUBSTR ( Line , a , b-a )
			WinCol := HB_USUBSTR ( Line , b + 1 , c-b  )

			* Determine Width
		
			a := HB_UAT ( " WIDTH " , HMG_UPPER (Line) )

			if a > 0

				Width := ''
				Started := .F.

				For z := a + 6 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == ' ' 
						if Started
							Exit
						EndIf
					Else
						if ! Started
							Started := .T.
						EndIf
						Width := Width + Char
					EndIf
				Next z

			EndIf

			* Determine Height
		
			a := HB_UAT ( " HEIGHT " , HMG_UPPER (Line) )

			if a > 0

				Height := ''
				Started := .F.

				For z := a + 7 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == ' ' 
						if Started
							Exit
						EndIf
					Else
						if ! Started
							Started := .T.
						EndIf
						Height := Height + Char
					EndIf
				Next z

			EndIf



			* Determine Virtual Width
		
			a := HB_UAT ( " VIRTUAL WIDTH " , HMG_UPPER (Line) )

			if a > 0

				VirtualWidth := ''
				Started := .F.

				For z := a + 14 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == ' ' 
						if Started
							Exit
						EndIf
					Else
						if ! Started
							Started := .T.
						EndIf
						VirtualWidth := VirtualWidth + Char
					EndIf
				Next z

			else

				VirtualWidth := 'Nil'

			EndIf

			if VirtualWidth = 'Nil'
				lVirtualForm := .F.
			else
				lVirtualForm := .T.
			endif

			* Determine Virtual Height
		
			a := HB_UAT ( " VIRTUAL HEIGHT " , HMG_UPPER (Line) )

			if a > 0

				VirtualHeight := ''
				Started := .F.

				For z := a + 15 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == ' ' 
						if Started
							Exit
						EndIf
					Else
						if ! Started
							Started := .T.
						EndIf
						VirtualHeight := VirtualHeight + Char
					EndIf
				Next z

			else

				VirtualHeight := 'Nil'

			EndIf

			if VirtualHeight = 'Nil'
				lVirtualForm := .F.
			else
				lVirtualForm := .T.
			endif

			__MVPUBLIC	( DesignForm + 'VirtualWidth' ) 
			__MVPUBLIC	( DesignForm + 'VirtualHeight' ) 
			__MVPUBLIC	( DesignForm + 'VirtualSized' ) 
			__MVPUT		( DesignForm + 'VirtualWidth' , VirtualWidth )
			__MVPUT		( DesignForm + 'VirtualHeight' , VirtualHeight )

			if VirtualHeight = 'Nil' .and. VirtualWidth = 'Nil'
				__MVPUT		( DesignForm + 'VirtualSized' , '.F.' )
			else
				__MVPUT		( DesignForm + 'VirtualSized' , '.T.' )
			endif


*

			* Determine Title
		
			a := HB_UAT ( " TITLE " , HMG_UPPER (Line) )

			Title := ''

			if a > 0

				For z := a + 8 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == '"' 
						exit
					Else
						Title := Title + Char
					EndIf
				Next z

			EndIf

			Title := ALLTRIM(Title)

			line := HB_URIGHT (line , HMG_LEN(line) - z )

			line := ALLTRIM(line)


			* Determine Icon

			Icon := ""		

			if line = 'ICON NIL'
				icon := ""
				line := HB_URIGHT ( line , HMG_LEN(line) - 8 )

			elseif line = 'ICON "'

				For z := 7 To HMG_LEN ( Line )
					char := HB_USUBSTR ( Line , z , 1 )
					if char == '"' 
						Exit
					Else
						Icon := Icon + Char
					EndIf
				Next z

				line := HB_URIGHT ( line , HMG_LEN(line) - z )

			EndIf

			Icon := ALLTRIM(Icon)

			line := ALLTRIM(line)


			* Determine Type

			if	line = "MAIN " 

				WindowType := 'MAIN'

			elseif	line = "MODAL " 

				WindowType := 'MODAL'		

			elseif  line = "CHILD " 

				WindowType := 'CHILD'

			elseif  line = "PANEL " 

				WindowType := 'PANEL'

			elseif line = "SPLITCHILD " 

				WindowType := 'SPLITCHILD'

			else

				WindowType := 'STANDARD'

				line := ' ' + line  
			endif

			/*
			MsgInfo ( WindowType , 'WindowType' )
			MsgInfo ( Width , 'Width' )
			MsgInfo ( Height , 'Height' )
			MsgInfo ( VirtualWidth , 'VirtualWidth' )
			MsgInfo ( VirtualHeight , 'VirtualHeight' )
                        */

			New(.F.)
			OpenFormName := FileName


			If ! Empty ( Width )
				SetProperty ( DesignForm , 'Width' , VAL (Width) )
			EndIf

			If ! Empty ( Height )
				SetProperty ( DesignForm , 'Height' , VAL (Height) )
			EndIf

			If ! Empty ( Title )
				SetProperty ( DesignForm , 'Title' , Title )
			EndIf


			If ! Empty ( WinRow )
				SetProperty ( DesignForm , 'Row' , VAL(WinRow) )
			EndIf

			If ! Empty ( WinCol )
				SetProperty ( DesignForm , 'Col' , VAL(WinCol) )
			EndIf

			__MVPUT ( DesignForm + 'WindowType' , WindowType )
			__MVPUT		( DesignForm + 'Icon' , Icon )

			////////////////////////////////////////////////////////
			If	WindowType == 'STANDARD' ;
				.Or. ;
				WindowType == 'MAIN' ;
				.Or. ;
				WindowType == 'CHILD' ;
				.Or. ;
				WindowType == 'PANEL' 

			////////////////////////////////////////////////////////

				*..............................................
				* Determine Caption
				*..............................................
		
				a := HB_UAT ( " NOCAPTION " , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'TitleBar' , '.F.' )
				Else
					__MVPUT ( DesignForm + 'TitleBar' , '.T.' )
				EndIf

				*..............................................
				* Determine SysMenu
				*..............................................
		
				a := HB_UAT ( " NOSYSMENU " , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'SysMenu' , '.F.' )
				Else
					__MVPUT ( DesignForm + 'SysMenu' , '.T.' )
				EndIf

				*..............................................
				* Determine Visible
				*..............................................
		
				a := HB_UAT ( " NOSHOW " , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'Visible' , '.F.' )
				Else
					__MVPUT ( DesignForm + 'Visible' , '.T.' )
				EndIf

				*..............................................
				* Determine Topmost
				*..............................................
		
				a := HB_UAT ( " TOPMOST " , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'Topmost' , '.T.' )
				Else
					__MVPUT ( DesignForm + 'Topmost' , '.F.' )
				EndIf

				*..............................................
				* Determine AutoRelease
				*..............................................
		
				a := HB_UAT ( " NOAUTORELEASE " , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'AutoRelease' , '.F.' )
				Else
					__MVPUT ( DesignForm + 'AutoRelease' , '.T.' )
				EndIf

				*..............................................
				* Determine MaxButton
				*..............................................
		
				a := HB_UAT ( " NOMAXIMIZE " , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'MaxButton' , '.F.' )
				Else
					__MVPUT ( DesignForm + 'MaxButton' , '.T.' )
				EndIf

				*..............................................
				* Determine MinButton
				*..............................................
		
				a := HB_UAT ( " NOMINIMIZE " , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'MinButton' , '.F.' )
				Else
					__MVPUT ( DesignForm + 'MinButton' , '.T.' )
				EndIf

				*..............................................
				* Determine Sizable
				*..............................................
		
				a := HB_UAT ( " NOSIZE " , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'Sizable' , '.F.' )
				Else
					__MVPUT ( DesignForm + 'Sizable' , '.T.' )
				EndIf

				*..............................................
				* Determine Cursor
				*..............................................
		
				a := HB_UAT ( " CURSOR " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 8 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 7 )

						if NextToken == 'ON INIT'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )

						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if HMG_UPPER (ClauseArgument) == 'NIL'
					ClauseArgument := ''
				Else
					ClauseArgument := HB_ULEFT ( ClauseArgument , HMG_LEN(ClauseArgument) - 1 )
					ClauseArgument := HB_URIGHT ( ClauseArgument , HMG_LEN(ClauseArgument) - 1 )
				EndIf

				__MVPUT ( DesignForm + 'Cursor' , ClauseArgument )

				*..............................................
				* Determine OnInit
				*..............................................
		
				a := HB_UAT ( " ON INIT " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 9 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 10 )

						if NextToken == 'ON RELEASE'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )

						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnInit' , ClauseArgument )

				*..............................................
				* Determine OnRelease
				*..............................................
		
				a := HB_UAT ( " ON RELEASE " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 12 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 19 )

						if NextToken == 'ON INTERACTIVECLOSE'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
		
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnRelease' , ClauseArgument )

				*..............................................
				* Determine OnInteractiveClose
				*..............................................
		
				a := HB_UAT ( " ON INTERACTIVECLOSE " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 21 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 13 )

						if NextToken == 'ON MOUSECLICK'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )

						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnInteractiveClose' , ClauseArgument )

				*..............................................
				* Determine OnMouseClick
				*..............................................
		
				a := HB_UAT ( " ON MOUSECLICK " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 15 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 12 )

						if NextToken == 'ON MOUSEDRAG'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )

						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
					
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnMouseClick' , ClauseArgument )

				*..............................................
				* Determine OnMouseDrag
				*..............................................
		
				a := HB_UAT ( " ON MOUSEDRAG " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 14 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 12 )

						if NextToken == 'ON MOUSEMOVE'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )

						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnMouseDrag' , ClauseArgument )

				* Determine OnMouseMove
		
				a := HB_UAT ( " ON MOUSEMOVE " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 14 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 7 )

						if NextToken == 'ON SIZE'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )

						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnMouseMove' , ClauseArgument )

				*..............................................
				* Determine OnSize
				*..............................................
		
				a := HB_UAT ( " ON SIZE " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 9 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 11 )

						if NextToken == 'ON MAXIMIZE'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnSize' , ClauseArgument )

				*..............................................
				* Determine OnMaximize
				*..............................................
		
				a := HB_UAT ( " ON MAXIMIZE " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 13 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 11 )

						if NextToken == 'ON MINIMIZE'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnMaximize' , ClauseArgument )

				*..............................................
				* Determine OnMinimize
				*..............................................
		
				a := HB_UAT ( " ON MINIMIZE " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 13 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 8 )

						if NextToken == 'ON PAINT'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnMinimize' , ClauseArgument )

				*..............................................
				* Determine OnPaint
				*..............................................
		
				a := HB_UAT ( " ON PAINT " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 10 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 9 )

						if NextToken == 'BACKCOLOR'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnPaint' , ClauseArgument )

				*..............................................
				* Determine BackColor
				*..............................................
		
				a := HB_UAT ( " BACKCOLOR " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 11 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 10 )

						if NextToken == 'NOTIFYICON'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'BackColor' , ClauseArgument )

				if ALLTRIM(HMG_UPPER(ClauseArgument)) = '{'
					SetWindowBackColor ( DesignFormHandle , &ClauseArgument )
				endif

				*..............................................
				* Determine NotifyIcon
				*..............................................

				a := HB_UAT ( " NOTIFYICON " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 12 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 13 )

						if NextToken == 'NOTIFYTOOLTIP'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

					if HMG_UPPER (ClauseArgument) == 'NIL'

						ClauseArgument := ''

					Else

						ClauseArgument := HB_ULEFT ( ClauseArgument , HMG_LEN(ClauseArgument) - 1 )
						ClauseArgument := HB_URIGHT ( ClauseArgument , HMG_LEN(ClauseArgument) - 1 )

					EndIf
        
				EndIf

				__MVPUT ( DesignForm + 'NotifyIcon' , ClauseArgument )

				*..............................................
				* Determine NotifyToolTip
				*..............................................
		
				a := HB_UAT ( " NOTIFYTOOLTIP " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 15 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 14 )

						if NextToken == 'ON NOTIFYCLICK'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

					if HMG_UPPER (ClauseArgument) == 'NIL'

						ClauseArgument := ''

					Else
	
						ClauseArgument := HB_ULEFT ( ClauseArgument , HMG_LEN(ClauseArgument) - 1 )
						ClauseArgument := HB_URIGHT ( ClauseArgument , HMG_LEN(ClauseArgument) - 1 )

					EndIf
        
				EndIf

				__MVPUT ( DesignForm + 'NotifyToolTip' , ClauseArgument )

				*..............................................
				* Determine OnNotifyClick
				*..............................................
		
				a := HB_UAT ( " ON NOTIFYCLICK " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 16 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 11 )

						if NextToken == 'ON GOTFOCUS'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnNotifyClick' , ClauseArgument )

				*..............................................
				* Determine OnGotFocus
				*..............................................
		
				a := HB_UAT ( " ON GOTFOCUS " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 13 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 12 )

						if NextToken == 'ON LOSTFOCUS'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnGotFocus' , ClauseArgument )

				*..............................................
				* Determine OnLostFocus
				*..............................................
		
				a := HB_UAT ( " ON LOSTFOCUS " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 14 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 11 )

						if NextToken == 'ON SCROLLUP'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnLostFocus' , ClauseArgument )

				*..............................................
				* Determine OnScrollUp
				*..............................................
		
				a := HB_UAT ( " ON SCROLLUP " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 13 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 13 )

						if NextToken == 'ON SCROLLDOWN'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnScrollUp' , ClauseArgument )
				*..............................................
				* Determine OnScrollDown
				*..............................................
		
				a := HB_UAT ( " ON SCROLLDOWN " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 15 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 13 )

						if NextToken == 'ON SCROLLLEFT'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnScrollDown' , ClauseArgument )
				*..............................................
				* Determine OnScrollLeft
				*..............................................
		
				a := HB_UAT ( " ON SCROLLLEFT " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 15 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 14 )

						if NextToken == 'ON SCROLLRIGHT'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnScrollLeft' , ClauseArgument )
				*..............................................
				* Determine OnScrollRight
				*..............................................
		
				a := HB_UAT ( " ON SCROLLRIGHT " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 16 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 13 )

						if NextToken == 'ON HSCROLLBOX'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnScrollRight' , ClauseArgument )
				*..............................................
				* Determine OnHScroolBox
				*..............................................
		
				a := HB_UAT ( " ON HSCROLLBOX " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 15 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 13 )

						if NextToken == 'ON VSCROLLBOX'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnHScrollBox' , ClauseArgument )

				*..............................................
				* Determine OnVScroolBox
				*..............................................
		
				a := HB_UAT ( " ON VSCROLLBOX " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 15 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 10 )

						if NextToken == 'HELPBUTTON'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnVScrollBox' , ClauseArgument )

				*..............................................
				* Determine HelpButton
				*..............................................
		
				a := HB_UAT ( " HELPBUTTON" , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'HelpButton' , '.T.' )
				EndIf

			////////////////////////////////////////////////////////
			ElseIf	WindowType == 'MODAL' 
			////////////////////////////////////////////////////////

				*..............................................
				* Determine Caption
				*..............................................
		
				a := HB_UAT ( " NOCAPTION " , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'TitleBar' , '.F.' )
				Else
					__MVPUT ( DesignForm + 'TitleBar' , '.T.' )
				EndIf

				*..............................................
				* Determine SysMenu
				*..............................................
		
				a := HB_UAT ( " NOSYSMENU " , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'SysMenu' , '.F.' )
				Else
					__MVPUT ( DesignForm + 'SysMenu' , '.T.' )
				EndIf

				*..............................................
				* Determine Visible
				*..............................................
		
				a := HB_UAT ( " NOSHOW " , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'Visible' , '.F.' )
				Else
					__MVPUT ( DesignForm + 'Visible' , '.T.' )
				EndIf

				*..............................................
				* Determine AutoRelease
				*..............................................
		
				a := HB_UAT ( " NOAUTORELEASE " , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'AutoRelease' , '.F.' )
				Else
					__MVPUT ( DesignForm + 'AutoRelease' , '.T.' )
				EndIf

				*..............................................
				* Determine Sizable
				*..............................................
		
				a := HB_UAT ( " NOSIZE " , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'Sizable' , '.F.' )
				Else
					__MVPUT ( DesignForm + 'Sizable' , '.T.' )
				EndIf

				*..............................................
				* Determine Cursor
				*..............................................
		
				a := HB_UAT ( " CURSOR " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 8 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 7 )

						if NextToken == 'ON INIT'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )

						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if HMG_UPPER (ClauseArgument) == 'NIL'
					ClauseArgument := ''
				Else
					ClauseArgument := HB_ULEFT ( ClauseArgument , HMG_LEN(ClauseArgument) - 1 )
					ClauseArgument := HB_URIGHT ( ClauseArgument , HMG_LEN(ClauseArgument) - 1 )
				EndIf

				__MVPUT ( DesignForm + 'Cursor' , ClauseArgument )

				*..............................................
				* Determine OnInit
				*..............................................
		
				a := HB_UAT ( " ON INIT " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 9 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 10 )

						if NextToken == 'ON RELEASE'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )

						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnInit' , ClauseArgument )

				*..............................................
				* Determine OnRelease
				*..............................................
		
				a := HB_UAT ( " ON RELEASE " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 12 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 19 )

						if NextToken == 'ON INTERACTIVECLOSE'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
		
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnRelease' , ClauseArgument )

				*..............................................
				* Determine OnInteractiveClose
				*..............................................
		
				a := HB_UAT ( " ON INTERACTIVECLOSE " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 21 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 13 )

						if NextToken == 'ON MOUSECLICK'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )

						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnInteractiveClose' , ClauseArgument )

				*..............................................
				* Determine OnMouseClick
				*..............................................
		
				a := HB_UAT ( " ON MOUSECLICK " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 15 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 12 )

						if NextToken == 'ON MOUSEDRAG'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )

						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
					
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnMouseClick' , ClauseArgument )

				*..............................................
				* Determine OnMouseDrag
				*..............................................
		
				a := HB_UAT ( " ON MOUSEDRAG " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 14 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 12 )

						if NextToken == 'ON MOUSEMOVE'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )

						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnMouseDrag' , ClauseArgument )

				*..............................................
				* Determine OnMouseMove
				*..............................................
		
				a := HB_UAT ( " ON MOUSEMOVE " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 14 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 7 )

						if NextToken == 'ON SIZE'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )

						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnMouseMove' , ClauseArgument )

				*..............................................
				* Determine OnSize
				*..............................................
		
				a := HB_UAT ( " ON SIZE " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 9 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 8 )

						if NextToken == 'ON PAINT'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnSize' , ClauseArgument )

				*..............................................
				* Determine OnPaint
				*..............................................
		
				a := HB_UAT ( " ON PAINT " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 10 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 9 )

						if NextToken == 'BACKCOLOR'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnPaint' , ClauseArgument )

				*..............................................
				* Determine BackColor
				*..............................................
		
				a := HB_UAT ( " BACKCOLOR " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 11 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 11 )

						if NextToken == 'ON GOTFOCUS'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'BackColor' , ClauseArgument )

				if ALLTRIM(HMG_UPPER(ClauseArgument)) = '{'
					SetWindowBackColor ( DesignFormHandle , &ClauseArgument )
				endif

				*..............................................
				* Determine OnGotFocus
				*..............................................
		
				a := HB_UAT ( " ON GOTFOCUS " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 13 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 12 )

						if NextToken == 'ON LOSTFOCUS'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnGotFocus' , ClauseArgument )

				*..............................................
				* Determine OnLostFocus
				*..............................................
		
				a := HB_UAT ( " ON LOSTFOCUS " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 14 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 11 )

						if NextToken == 'ON SCROLLUP'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnLostFocus' , ClauseArgument )

				*..............................................
				* Determine OnScrollUp
				*..............................................
		
				a := HB_UAT ( " ON SCROLLUP " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 13 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 13 )

						if NextToken == 'ON SCROLLDOWN'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnScrollUp' , ClauseArgument )
				*..............................................
				* Determine OnScrollDown
				*..............................................
		
				a := HB_UAT ( " ON SCROLLDOWN " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 15 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 13 )

						if NextToken == 'ON SCROLLLEFT'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnScrollDown' , ClauseArgument )
				*..............................................
				* Determine OnScrollLeft
				*..............................................
		
				a := HB_UAT ( " ON SCROLLLEFT " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 15 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 14 )

						if NextToken == 'ON SCROLLRIGHT'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnScrollLeft' , ClauseArgument )
				*..............................................
				* Determine OnScrollRight
				*..............................................
		
				a := HB_UAT ( " ON SCROLLRIGHT " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 16 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 13 )

						if NextToken == 'ON HSCROLLBOX'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnScrollRight' , ClauseArgument )
				*..............................................
				* Determine OnHScroolBox
				*..............................................
		
				a := HB_UAT ( " ON HSCROLLBOX " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 15 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 13 )

						if NextToken == 'ON VSCROLLBOX'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnHScrollBox' , ClauseArgument )
				*..............................................
				* Determine OnVScroolBox
				*..............................................
		
				a := HB_UAT ( " ON VSCROLLBOX " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 15 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 10 )

						if NextToken == 'HELPBUTTON'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnVScrollBox' , ClauseArgument )

				*..............................................
				* Determine HelpButton
				*..............................................
		
				a := HB_UAT ( " HELPBUTTON" , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'HelpButton' , '.T.' )
				EndIf

			////////////////////////////////////////////////////////
			ElseIf	WindowType == 'SPLITCHILD' 
			////////////////////////////////////////////////////////

				*..............................................
				* Determine Caption
				*..............................................
		
				a := HB_UAT ( " NOCAPTION " , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'TitleBar' , '.F.' )
				Else
					__MVPUT ( DesignForm + 'TitleBar' , '.T.' )
				EndIf

				*..............................................
				* Determine Break
				*..............................................
		
				a := HB_UAT ( " BREAK " , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'Break' , '.T.' )
				Else
					__MVPUT ( DesignForm + 'Break' , '.F.' )
				EndIf

				*..............................................
				* Determine Focused
				*..............................................
		
				a := HB_UAT ( " FOCUSED " , HMG_UPPER (Line) )

				if a > 0
					__MVPUT ( DesignForm + 'Focused' , '.T.' )
				Else
					__MVPUT ( DesignForm + 'Focused' , '.F.' )
				EndIf

				*..............................................
				* Determine Cursor
				*..............................................
		
				a := HB_UAT ( " CURSOR " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 8 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 11 )
						if NextToken == 'ON GOTFOCUS'
							Exit
						endif
						NextToken := HB_USUBSTR ( Line , z , 11 )
						if NextToken == 'GRIPPERTEXT'
							Exit
						endif
						NextToken := HB_USUBSTR ( Line , z , 5 )
						if NextToken == 'BREAK'
							Exit
						endif
						NextToken := HB_USUBSTR ( Line , z , 7 )
						if NextToken == 'FOCUSED'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )

						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if HMG_UPPER (ClauseArgument) == 'NIL'
					ClauseArgument := ''
				Else
					ClauseArgument := HB_ULEFT ( ClauseArgument , HMG_LEN(ClauseArgument) - 1 )
					ClauseArgument := HB_URIGHT ( ClauseArgument , HMG_LEN(ClauseArgument) - 1 )
				EndIf

				__MVPUT ( DesignForm + 'Cursor' , ClauseArgument )

				*..............................................
				* Determine GripperText
				*..............................................
		
				a := HB_UAT ( " GRIPPERTEXT " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 13 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 5 )
						if NextToken == 'BREAK'
							Exit
						endif
						NextToken := HB_USUBSTR ( Line , z , 7 )
						if NextToken == 'FOCUSED'
							Exit
						endif
						NextToken := HB_USUBSTR ( Line , z , 11 )
						if NextToken == 'ON GOTFOCUS'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )

						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )

				EndIf

				if HMG_UPPER (ClauseArgument) == 'NIL'
					ClauseArgument := ''
				Else
					ClauseArgument := HB_ULEFT ( ClauseArgument , HMG_LEN(ClauseArgument) - 1 )
					ClauseArgument := HB_URIGHT ( ClauseArgument , HMG_LEN(ClauseArgument) - 1 )
				EndIf

				__MVPUT ( DesignForm + 'GripperText' , ClauseArgument )

				*..............................................
				* Determine OnGotFocus
				*..............................................
		
				a := HB_UAT ( " ON GOTFOCUS " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 13 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 12 )

						if NextToken == 'ON LOSTFOCUS'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnGotFocus' , ClauseArgument )

				*..............................................
				* Determine OnLostFocus
				*..............................................
		
				a := HB_UAT ( " ON LOSTFOCUS " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 14 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 11 )

						if NextToken == 'ON SCROLLUP'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnLostFocus' , ClauseArgument )


				*..............................................
				* Determine OnScrollUp
				*..............................................
		
				a := HB_UAT ( " ON SCROLLUP " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 13 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 13 )

						if NextToken == 'ON SCROLLDOWN'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnScrollUp' , ClauseArgument )
				*..............................................
				* Determine OnScrollDown
				*..............................................
		
				a := HB_UAT ( " ON SCROLLDOWN " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 15 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 13 )

						if NextToken == 'ON SCROLLLEFT'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnScrollDown' , ClauseArgument )
				*..............................................
				* Determine OnScrollLeft
				*..............................................
		
				a := HB_UAT ( " ON SCROLLLEFT " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 15 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 14 )

						if NextToken == 'ON SCROLLRIGHT'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnScrollLeft' , ClauseArgument )
				*..............................................
				* Determine OnScrollRight
				*..............................................
		
				a := HB_UAT ( " ON SCROLLRIGHT " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 16 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 13 )

						if NextToken == 'ON HSCROLLBOX'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnScrollRight' , ClauseArgument )
				*..............................................
				* Determine OnHScroolBox
				*..............................................
		
				a := HB_UAT ( " ON HSCROLLBOX " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 15 To HMG_LEN ( Line )

						NextToken := HB_USUBSTR ( Line , z , 13 )

						if NextToken == 'ON VSCROLLBOX'
							Exit
						endif

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnHScrollBox' , ClauseArgument )
				*..............................................
				* Determine OnVScroolBox
				*..............................................
		
				a := HB_UAT ( " ON VSCROLLBOX " , HMG_UPPER (Line) )

				ClauseArgument := ''

				if a > 0

					Started := .F.

					For z := a + 15 To HMG_LEN ( Line )

						char := HB_USUBSTR ( Line , z , 1 )
			
						ClauseArgument := ClauseArgument + Char

					Next z

					ClauseArgument := ALLTRIM ( ClauseArgument )
        
				EndIf

				if Empty ( ClauseArgument )
					ClauseArgument := 'Nil'
				EndIf

				__MVPUT ( DesignForm + 'OnVScrollBox' , ClauseArgument )

			EndIf

		EndIf



	Next i

	loading.hide

	UpdateCombo()
	Properties.Combo_1.Value := 1
	DesignFormModified := .F.

	if ! _IsWindowDefined ( 'Form_1' )

		__MVPUBLIC	( DesignForm + 'VirtualWidth' ) 
		__MVPUBLIC	( DesignForm + 'VirtualHeight' ) 
		__MVPUBLIC	( DesignForm + 'VirtualSized' ) 
		__MVPUT		( DesignForm + 'VirtualWidth' , 'Nil' )
		__MVPUT		( DesignForm + 'VirtualHeight' , 'Nil' )
		__MVPUT		( DesignForm + 'VirtualSized' , '.F.' )

		lVirtualForm := .F.

		New(.F.)
		OpenFormName := FileName

	endif

	UpdateDesignFormProperties()

	If nComponentCount > 0
		Form_main.user.enabled := .T.
	EndIf

	DoMethod (DesignForm , 'Activate')

	If nComponentCount > 0
		Form_main.user.enabled := .F.
	EndIf

	lVirtualForm := .F.

RETURN

*------------------------------------------------------------------------------*
// PROCEDURE RemoveExtraSpaces (Line)
FUNCTION RemoveExtraSpaces (Line)
*------------------------------------------------------------------------------*
Local i , l , c , p , NewLine

	l := HMG_LEN (Line)

	p := ''
	NewLine := ''

	For i := 1 To l

		c := HB_USUBSTR ( Line , i , 1 )

		if ! ( c == ' ' .and. p == ' ' )

			if c != chr (8)
				NewLine := NewLine + c
			endif

		EndIf
		
		p := c

	Next i

RETURN ( NewLine )
