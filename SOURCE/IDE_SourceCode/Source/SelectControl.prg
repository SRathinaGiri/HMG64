*------------------------------------------------------------------------------*
PROCEDURE SelectControl( ControlName )
*------------------------------------------------------------------------------*
Local FocusHandle
Local i
Local Row 
Local Col 
Local Width 
Local Height 
Local x
Local y
Local z
Local aTemp := {}
Local cTemp := ''
Local dTemp := ''
Local ey
Local ez
Local eaTemp := {}
Local ecTemp := ''
Local edTemp := ''
Local DC
Local DR

	If ! _IsControlDefined (ControlName,DesignForm)
		redrawwindow(DesignFormhandle)
		DrawGrid()
		RETURN 
	EndIf

	if lVirtualForm
		DC := GetScrollPos ( DesignFormhandle , SB_HORZ )  
		DR := GetScrollPos ( DesignFormhandle , SB_VERT )  
	else
		DC := 0
		DR := 0
	endif

	If .not. empty(SelectedControlName)

		x := GetControlIndex (SelectedControlName,DesignForm)
	
		If x > 0

			Row := _HMG_SYSDATA [ 18 ] [x]
			Col := _HMG_SYSDATA [ 19 ] [x]
			Width := _HMG_SYSDATA [ 20 ] [x]
			Height := _HMG_SYSDATA [ 21 ] [x]

			RedrawRect ( DesignFormhandle , Row - 10 - DR , Col - 10 - DC , Row+Height+10 , Col+Width+10 )

		EndIf

	EndIf

	SelectedControlName := ControlName

	WindowWidth := GetWindowWidth ( DesignFormHandle )
	WindowHeight := GetWindowHeight ( DesignFormHandle )

	i := GetControlIndex ( ControlName , DesignForm )

	If	_HMG_SYSDATA [ 1 ] [ i ] == 'BUTTON' .and. _HMG_SYSDATA [ 39 ] [ i ] == 0
		SelectedControlType := 'BUTTON'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'CHECKBOX' .and. _HMG_SYSDATA [ 39 ] [ i ] == 0
		SelectedControlType := 'CHECKBOX'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LIST'
		SelectedControlType := 'LISTBOX'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'COMBO'
		SelectedControlType := 'COMBOBOX'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'CHECKBOX' .and. _HMG_SYSDATA [ 39 ] [ i ] == 1
		SelectedControlType := 'CHECKBUTTON'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'GRID'
		SelectedControlType := 'GRID'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'SLIDER'
		SelectedControlType := 'SLIDER'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'SPINNER'
		SelectedControlType := 'SPINNER'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'IMAGE'
		SelectedControlType := 'IMAGE'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'TREE'
		SelectedControlType := 'TREE'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'DATEPICK'
		SelectedControlType := 'DATEPICKER'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'TEXT'
		SelectedControlType := 'TEXTBOX'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'EDIT'
		SelectedControlType := 'EDITBOX'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 0
		SelectedControlType := 'LABEL'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'BROWSE'
		SelectedControlType := 'BROWSE'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'RADIOGROUP'
		SelectedControlType := 'RADIOGROUP'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'FRAME'
		SelectedControlType := 'FRAME'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'TAB'
		SelectedControlType := 'TAB'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'ANIMATEBOX'
		SelectedControlType := 'ANIMATEBOX'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 6
		SelectedControlType := 'HYPERLINK'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 7
		SelectedControlType := 'ACTIVEX'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 8
		SelectedControlType := 'WINDOW'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'MONTHCAL'
		SelectedControlType := 'MONTHCALENDAR'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'RICHEDIT'
		SelectedControlType := 'RICHEDITBOX'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 2
		SelectedControlType := 'PROGRESSBAR'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 3
		SelectedControlType := 'PLAYER'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 4
		SelectedControlType := 'IPADDRESS'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'BUTTON' .and. _HMG_SYSDATA [ 39 ] [ i ] == 5
		SelectedControlType := 'TIMER'
	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] > 10
		SelectedControlType := 'USER'
	Else
		SelectedControlType := ''
	EndIf

	FocusHandle := _HMG_SYSDATA [   3 ] [i]

	SelectedControlIndex := i

	Row := _HMG_SYSDATA [ 18 ] [i]
	Col := _HMG_SYSDATA [ 19 ] [i]
	Width := _HMG_SYSDATA [ 20 ] [i]
	Height := _HMG_SYSDATA [ 21 ] [i]


	z := Properties.grid_1.value

	if z != 0
		aTemp := properties.grid_1.item(z)
		cTemp := ALLTRIM ( HMG_UPPER ( aTemp [1] ) )
	endif



	ez := Properties.grid_2.value

	if ez != 0
		eaTemp := properties.grid_2.item(ez)
		ecTemp := ALLTRIM ( HMG_UPPER ( eaTemp [1] ) )
	endif



	UpdateControlProperties (i)

	if ! empty ( cTemp )	

		z := Properties.grid_1.itemcount

		for y := 1 to z

			aTemp := properties.grid_1.item(y)
			dTemp := ALLTRIM ( HMG_UPPER ( aTemp [1] ) )

			if cTemp == dTemp
				Properties.grid_1.value := y
				exit
			endif

		next y

	end if

	if Properties.grid_1.value == 0
		Properties.grid_1.value := 1
	endif



	if ! empty ( ecTemp )	

		ez := Properties.grid_2.itemcount

		for ey := 1 to ez

			eaTemp := properties.grid_2.item(ey)
			edTemp := ALLTRIM ( HMG_UPPER ( eaTemp [1] ) )

			if ecTemp == edTemp
				Properties.grid_2.value := ey
				exit
			endif

		next ey

	end if

	if Properties.grid_2.value == 0
		Properties.grid_2.value := 1
	endif


	rectdraw( DesignFormhandle,Row - 6 - DR			,Col - 6 - DC			,Row -1	- DR			,Col -1	- DC			, BLACK,4,WHITE,.t.)

	linedraw( DesignFormhandle,Row - 3 - DR			,Col - 3 - DC			,Row - 3 - DR			,Col - 3 -DC			, BLACK,6)
	linedraw( DesignFormhandle,Row + Height + 3 - DR	,Col - 3 - DC			,Row + Height + 3 - DR		,Col - 3 -DC			, BLACK,6)
	linedraw( DesignFormhandle,Row - 3 - DR			,Col + Width + 3 - DC		,Row - 3 - DR			,Col + Width + 3 - DC		, BLACK,6)
	linedraw( DesignFormhandle,Row - 3 - DR			,Col + ( Width / 2 ) - DC	,Row - 3 - DR			,Col + ( Width / 2 ) - DC	, BLACK,6)
	linedraw( DesignFormhandle,Row + Height + 3 - DR	,Col + ( Width / 2 ) - DC	,Row + Height + 3 - DR		,Col + ( Width / 2 ) - DC	, BLACK,6)
	linedraw( DesignFormhandle,Row + ( Height / 2 ) - DR	,Col - 3 - DC			,Row + ( Height / 2 ) - DR	,Col - 3 - DC			, BLACK,6)
	linedraw( DesignFormhandle,Row + ( Height / 2 ) - DR	,Col + Width + 3 - DC		,Row + ( Height / 2 ) - DR	,Col + Width + 3 - DC		, BLACK,6)
	linedraw( DesignFormhandle,Row + Height + 4 - DR	,Col + Width - 4 - DC		,Row + Height + 4 - DR		,Col + Width + 4 - DC 		, BLACK,3)
	linedraw( DesignFormhandle,Row + Height - 4 - DR	,Col + Width + 4 - DC		,Row + Height + 4 - DR		,Col + Width + 4 - DC		, BLACK,3)

	DoMethod ( DesignForm , 'Text_Dummy' , 'SetFocus' )

	If _HMG_SYSDATA [ 1 ] [i] != 'RADIO' .and. _HMG_SYSDATA [ 1 ] [i] != 'SPINNER' .and. _HMG_SYSDATA [ 1 ] [i] != 'TAB'

		RedrawWindow (FocusHandle)

	EndIf

	UpdateCombo()
        	
	For i := 1 To Properties.Combo_1.ItemCount
		If Properties.Combo_1.Item ( i ) == SelectedControlName
**********		Properties.Combo_1.Value := i 
			ComboSetCursel ( GetControlHandle('Combo_1','Properties') , i )
			Exit
		EndIf
	Next i

	DrawGrid()

RETURN
