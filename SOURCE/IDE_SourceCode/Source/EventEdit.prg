*------------------------------------------------------------------------------*
PROCEDURE EventEdit()
*------------------------------------------------------------------------------*
LOCAL Result
Local i , aRow , EventName ,st , cSnippetName , x , cDefaultValue , cWindowName , cTemp

	i := Properties.Grid_2.Value

	if i == 0
		RETURN
	EndIf

	aRow := Properties.Grid_2.Item (i)

	EventName := ALLTRIM ( HMG_UPPER ( aRow [1] ) )

	***********************************************************************
	* Begin User *
	***********************************************************************

	If SelectedControlType == 'USER'

		Result := ALLTRIM ( PickCharacterPropertyValue ( aMsgs [ 131 ] , aRow [1] + ':' , aRow [2] ) )

		If _HMG_SYSDATA [ 257 ] == .F.

			DesignFormModified := .T.

			if ! Empty ( SelectedControlName )

				__MVPUT( SelectedControlName + EventName , Result )
				SelectControl (SelectedControlName)

			EndIf

		EndIf

		RETURN

	EndIf

	***********************************************************************
	* End User *
	***********************************************************************

	If EventName == 'ONHSCROLLBOX' .And. !lVirtualForm
		Playhand()
		RETURN
	EndIf
	If EventName == 'ONVSCROLLBOX' .And. !lVirtualForm
		Playhand()
		RETURN
	EndIf
	If EventName == 'ONSCROLLDOWN' .And. !lVirtualForm
		Playhand()
		RETURN
	EndIf
	If EventName == 'ONSCROLLLEFT' .And. !lVirtualForm
		Playhand()
		RETURN
	EndIf
	If EventName == 'ONSCROLLRIGHT' .And. !lVirtualForm
		Playhand()
		RETURN
	EndIf
	If EventName == 'ONSCROLLEIGHT' .And. !lVirtualForm
		Playhand()
		RETURN
	EndIf
	If EventName == 'ONSCROLLUP' .And. !lVirtualForm
		Playhand()
		RETURN
	EndIf

	if This.CellColIndex == 1

		RETURN

	elseif This.CellColIndex == 2

		Result := ALLTRIM ( PickCharacterPropertyValue ( aMsgs [ 131 ] , aRow [1] + ':' , aRow [2] ) )

	elseif This.CellColIndex == 3


		cDefaultValue := ALLTRIM( HB_USUBSTR ( properties.title , HB_UAT('[',properties.title) + 1 , 255 ) ) 

		cDefaultValue := HB_ULEFT ( cDefaultValue , HB_UAT( '.' , cDefaultValue ) - 1 ) + '_'

		cDefaultValue += ALLTRIM(properties.combo_1.item(properties.combo_1.value)) + '_' + ALLTRIM(aRow[1])

		cDefaultValue := HMG_LOWER(cDefaultValue)

		Result := ALLTRIM ( PickCharacterPropertyValue ( aMsgs [ 071 ] , aRow [1] + ':' , cDefaultValue ) )


		if HB_URIGHT (result , 2 ) == '()'

			result := HB_ULEFT ( result , HMG_LEN(result) - 2 )

		endif

		if HMG_LOWER(ALLTRIM(HB_URIGHT (result , 4 ))) == '.prg'

			result := HB_ULEFT ( result , HMG_LEN(result) - 4 )

		endif


		cTemp := aRow [2]

		if HB_URIGHT ( cTemp , 2 ) == '()'

			cTemp := HB_ULEFT ( cTemp , HMG_LEN(cTemp) - 2 )

		endif



		if file ( cTemp + '.prg' )

			if MsgYesNo ( aMsgs [ 073 ] , 'HMG-IDE' )

				DELETE FILE (cTemp + '.prg')

				for x := 1 to Project.List_1.ItemCount
					
					if HMG_UPPER(ALLTRIM(Project.List_1.Item(x)))==HMG_UPPER(ALLTRIM(cTemp + '.prg'))

						Project.List_1.DeleteItem (x)

						SaveProject()

						SortModuleList()

					endif

				next x

			endif

		endif


		If _HMG_SYSDATA [ 257 ] == .F.

			cTemp := ALLTRIM( HB_USUBSTR ( properties.title , HB_UAT('[',properties.title) + 1 , 255 ) ) 

			cWindowName := HB_ULEFT ( cTemp , HB_UAT( '.' , cTemp ) - 1 ) 

                	
			st := CreateCodeSnippet(Result , cWindowName )

			if st == .f.

				_HMG_SYSDATA [ 257 ] := .T.

			else

				result := result + '()'

			endif

		EndIf

	elseif This.CellColIndex == 4

		cSnippetName := ALLTRIM ( aRow [2] )

		if HB_URIGHT ( cSnippetName , 2 ) == '()'

			cSnippetName := HB_ULEFT ( cSnippetName , HMG_LEN(cSnippetName) - 2 )

		endif

		cSnippetName +=  '.prg' 

		if file (cSnippetName)

			if msgyesno( aMsgs [ 099 ] , aMsgs [ 007 ] + ' ' + cSnippetName )

				DELETE FILE (cSnippetName)

				Properties.Grid_2.cell(i,2) := 'Nil'

				Result := 'Nil'

				for x := 1 to Project.List_1.ItemCount
					
					if HMG_UPPER(ALLTRIM(Project.List_1.Item(x)))==HMG_UPPER(ALLTRIM(cSnippetName))

						Project.List_1.DeleteItem (x)

						SaveProject()

						SortModuleList()

					endif

				next x

			endif

		else

			MsgStop ( aMsgs [162] ,'HMG-IDE' )
			_HMG_SYSDATA [ 257 ] := .T.

		endif

	elseif This.CellColIndex == 5

		cSnippetName := ALLTRIM ( aRow [2] )

		if HB_URIGHT ( cSnippetName , 2 ) == '()'

			cSnippetName := HB_ULEFT ( cSnippetName , HMG_LEN(cSnippetName) - 2 )

		endif

		cSnippetName +=  '.prg' 

		if file (cSnippetName)

			EXECUTE FILE ProgramEditor PARAMETERS cSnippetName

			RETURN

		else

			MsgStop ( aMsgs [162] ,'HMG-IDE' )

			RETURN

		endif

	else

		RETURN

	endif

	If _HMG_SYSDATA [ 257 ] == .F.

		DesignFormModified := .T.

		if ! Empty ( SelectedControlName )

			Properties.Grid_2.Item (i) := { aRow [1] , Result }

			If	SelectedControlType == 'BUTTON'

				If EventName == 'ACTION'
					__MVPUT( SelectedControlName + 'Action' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONGOTFOCUS'
					__MVPUT( SelectedControlName + 'OnGotFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONLOSTFOCUS'
					__MVPUT( SelectedControlName + 'OnlostFocus' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'CHECKBOX'

				If EventName == 'ONCHANGE'
					__MVPUT( SelectedControlName + 'OnChange' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONGOTFOCUS'
					__MVPUT( SelectedControlName + 'OnGotFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONLOSTFOCUS'
					__MVPUT( SelectedControlName + 'OnlostFocus' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'LISTBOX'

				If EventName == 'ONCHANGE'
					__MVPUT( SelectedControlName + 'OnChange' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONGOTFOCUS'
					__MVPUT( SelectedControlName + 'OnGotFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONLOSTFOCUS'
					__MVPUT( SelectedControlName + 'OnlostFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONDBLCLICK'
					__MVPUT( SelectedControlName + 'OnDblClick' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'COMBOBOX'

				If EventName == 'ONCHANGE'
					__MVPUT( SelectedControlName + 'OnChange' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONGOTFOCUS'
					__MVPUT( SelectedControlName + 'OnGotFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONLOSTFOCUS'
					__MVPUT( SelectedControlName + 'OnlostFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONENTER'
					__MVPUT( SelectedControlName + 'OnEnter' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONDISPLAYCHANGE'
					__MVPUT( SelectedControlName + 'OnDisplayChange' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONDROPDOWN'
					__MVPUT( SelectedControlName + 'OnDropDown' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONCLOSEUP'
					__MVPUT( SelectedControlName + 'OnCloseUp' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'CHECKBUTTON'

				If EventName == 'ONCHANGE'
					__MVPUT( SelectedControlName + 'OnChange' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONGOTFOCUS'
					__MVPUT( SelectedControlName + 'OnGotFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONLOSTFOCUS'
					__MVPUT( SelectedControlName + 'OnlostFocus' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'GRID'

				If EventName == 'ONCHANGE'
					__MVPUT( SelectedControlName + 'OnChange' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONGOTFOCUS'
					__MVPUT( SelectedControlName + 'OnGotFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONLOSTFOCUS'
					__MVPUT( SelectedControlName + 'OnlostFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONDBLCLICK'
					__MVPUT( SelectedControlName + 'OnDblClick' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONHEADCLICK'
					__MVPUT( SelectedControlName + 'OnHeadClick' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONQUERYDATA'
					__MVPUT( SelectedControlName + 'OnQueryData' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONSAVE'
					__MVPUT( SelectedControlName + 'OnSave' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'SLIDER'

				If EventName == 'ONCHANGE'
					__MVPUT( SelectedControlName + 'OnChange' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'SPINNER'

				If EventName == 'ONCHANGE'
					__MVPUT( SelectedControlName + 'OnChange' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONGOTFOCUS'
					__MVPUT( SelectedControlName + 'OnGotFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONLOSTFOCUS'
					__MVPUT( SelectedControlName + 'OnlostFocus' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'IMAGE'

				If EventName == 'ACTION'
					__MVPUT( SelectedControlName + 'Action' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'TREE'

				If EventName == 'ONCHANGE'
					__MVPUT( SelectedControlName + 'OnChange' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONGOTFOCUS'
					__MVPUT( SelectedControlName + 'OnGotFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONLOSTFOCUS'
					__MVPUT( SelectedControlName + 'OnlostFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONDBLCLICK'
					__MVPUT( SelectedControlName + 'OnDblClick' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'DATEPICKER'

				If EventName == 'ONCHANGE'
					__MVPUT( SelectedControlName + 'OnChange' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONGOTFOCUS'
					__MVPUT( SelectedControlName + 'OnGotFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONLOSTFOCUS'
					__MVPUT( SelectedControlName + 'OnlostFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONENTER'
					__MVPUT( SelectedControlName + 'OnEnter' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'TEXTBOX'

				If EventName == 'ONCHANGE'
					__MVPUT( SelectedControlName + 'OnChange' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONGOTFOCUS'
					__MVPUT( SelectedControlName + 'OnGotFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONLOSTFOCUS'
					__MVPUT( SelectedControlName + 'OnlostFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONENTER'
					__MVPUT( SelectedControlName + 'OnEnter' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'EDITBOX'

				If EventName == 'ONCHANGE'
					__MVPUT( SelectedControlName + 'OnChange' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONGOTFOCUS'
					__MVPUT( SelectedControlName + 'OnGotFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONLOSTFOCUS'
					__MVPUT( SelectedControlName + 'OnlostFocus' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'LABEL'
				If EventName == 'ACTION'
					__MVPUT( SelectedControlName + 'Action' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'BROWSE'

				If EventName == 'ONCHANGE'
					__MVPUT( SelectedControlName + 'OnChange' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONGOTFOCUS'
					__MVPUT( SelectedControlName + 'OnGotFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONLOSTFOCUS'
					__MVPUT( SelectedControlName + 'OnlostFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONDBLCLICK'
					__MVPUT( SelectedControlName + 'OnDblClick' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONHEADCLICK'
					__MVPUT( SelectedControlName + 'OnHeadClick' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'RADIOGROUP'

				If EventName == 'ONCHANGE'
					__MVPUT( SelectedControlName + 'OnChange' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'FRAME'

			ElseIf	SelectedControlType == 'ANIMATEBOX'

			ElseIf	SelectedControlType == 'HYPERLINK'

			ElseIf	SelectedControlType == 'MONTHCALENDAR'

				If EventName == 'ONCHANGE'
					__MVPUT( SelectedControlName + 'OnChange' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'RICHEDITBOX'

				If EventName == 'ONCHANGE'
					__MVPUT( SelectedControlName + 'OnChange' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONGOTFOCUS'
					__MVPUT( SelectedControlName + 'OnGotFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONLOSTFOCUS'
					__MVPUT( SelectedControlName + 'OnlostFocus' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'PROGRESSBAR'

			ElseIf	SelectedControlType == 'PLAYER'

			ElseIf	SelectedControlType == 'IPADDRESS'

				If EventName == 'ONCHANGE'
					__MVPUT( SelectedControlName + 'OnChange' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONGOTFOCUS'
					__MVPUT( SelectedControlName + 'OnGotFocus' , Result )
					SelectControl (SelectedControlName)
				ElseIf EventName == 'ONLOSTFOCUS'
					__MVPUT( SelectedControlName + 'OnlostFocus' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'TAB'

				If EventName == 'ONCHANGE'
					__MVPUT( SelectedControlName + 'OnChange' , Result )
					SelectControl (SelectedControlName)
				EndIf

			ElseIf	SelectedControlType == 'TIMER'

				If EventName == 'ACTION'
					__MVPUT( SelectedControlName + 'Action' , Result )
					SelectControl (SelectedControlName)
				EndIf

			EndIf

		Else

			If EventName == 'ONINIT'

				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'OnInit' , Result )

			ElseIf EventName == 'ONRELEASE'

				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'OnRelease' , Result )

			ElseIf EventName == 'ONINTERACTIVECLOSE'

				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'OnInteractiveClose' , Result )

			ElseIf EventName == 'ONMOUSECLICK'

				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'OnMouseClick' , Result )

			ElseIf EventName == 'ONMOUSEDRAG'

				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'OnMouseDrag' , Result )

			ElseIf EventName == 'ONMOUSEMOVE'

				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'OnMouseMove' , Result )

			ElseIf EventName == 'ONSIZE'

				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'OnSize' , Result )

			ElseIf EventName == 'ONMAXIMIZE'

				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'OnMaximize' , Result )

			ElseIf EventName == 'ONMINIMIZE'

				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'OnMinimize' , Result )

			ElseIf EventName == 'ONPAINT'

				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'OnPaint' , Result )

			ElseIf EventName == 'ONNOTIFYCLICK'

				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'OnNotifyClick' , Result )

			ElseIf EventName == 'ONGOTFOCUS'

				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'OnGotFocus' , Result )

			ElseIf EventName == 'ONLOSTFOCUS'

				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'OnLostFocus' , Result )

			ElseIf EventName == 'ONSCROLLUP'
				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'ONSCROLLUP' , Result )

			ElseIf EventName == 'ONSCROLLDOWN'
				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'ONSCROLLDOWN' , Result )

			ElseIf EventName == 'ONSCROLLLEFT'
				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'ONSCROLLLEFT' , Result )

			ElseIf EventName == 'ONSCROLLRIGHT'
				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'ONSCROLLRIGHT' , Result )

			ElseIf EventName == 'ONHSCROLLBOX'
				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'ONHSCROLLBOX' , Result )

			ElseIf EventName == 'ONVSCROLLBOX'
				Properties.Grid_2.Item (i) := { aRow [1] , Result }
				__MVPUT( DesignForm + 'ONVSCROLLBOX' , Result )

			EndIf

		EndIf

		Properties.Grid_2.Value := i
		Properties.Grid_2.SetFocus

	Else

		if ! Empty ( SelectedControlName )
			SelectControl (SelectedControlName)
		EndIf

		Properties.Grid_2.Value := i
		Properties.Grid_2.SetFocus

	EndIf

RETURN
