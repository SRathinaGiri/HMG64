*------------------------------------------------------------------------------*
Function NewForm ( cNewForm )
*------------------------------------------------------------------------------*
Local Result
Local i
Local cFormContent
Local lRetVal := .T.


	InitControlCounters()

	If Empty ( Projectname )
		MsgStop ( aMsgs [ 085 ] ,'HMG IDE')
		Return NIL
	EndIf

	_HMG_SYSDATA [ 257 ] := .F.

	If VALTYPE (cNewForm) = 'U'

		Result := ALLTRIM ( InputBox ( aMsgs [ 152 ]  , aMsgs [ 153 ]  , '' ) )
	
	Else

		Result := cNewForm

	EndIf

	If _HMG_SYSDATA [ 257 ] == .T.
		If _IsWindowDefined ( DesignForm )
			SelectControl (SelectedControlName)
			DrawGrid()
		endif
		Return NIL
	EndIf

	If Empty ( Result )
		If _IsWindowDefined ( DesignForm )
			SelectControl (SelectedControlName)
			DrawGrid()
		endif
		Return NIL
	EndIf

	Result := ALLTRIM (Result)

	If HMG_UPPER ( HB_URIGHT ( Result,4 ) ) != '.FMG'
		Result := Result + '.Fmg'
	EndIf

	For i := 1 To Project.List_2.ItemCount
		if ALLTRIM( HMG_UPPER(Project.List_2.Item(i)) ) == ALLTRIM( HMG_UPPER(result) )
			MsgStop( aMsgs [ 157 ]  , 'HMG IDE' )
			Return NIL
		endif
	next i


	If VALTYPE (cNewForm) = 'U'

		cFormContent := ''
		cFormContent += 'DEFINE WINDOW TEMPLATE AT 132 , 235 WIDTH 550 HEIGHT 350 VIRTUAL WIDTH Nil VIRTUAL HEIGHT Nil TITLE "" ICON NIL  CURSOR NIL ON INIT Nil ON RELEASE Nil ON INTERACTIVECLOSE Nil ON MOUSECLICK Nil ON MOUSEDRAG Nil ON MOUSEMOVE Nil ON SIZE Nil ON MAXIMIZE Nil ON MINIMIZE Nil ON PAINT Nil BACKCOLOR Nil NOTIFYICON NIL NOTIFYTOOLTIP NIL ON NOTIFYCLICK Nil ON GOTFOCUS Nil ON LOSTFOCUS Nil ON SCROLLUP Nil ON SCROLLDOWN Nil ON SCROLLLEFT Nil ON SCROLLRIGHT Nil ON HSCROLLBOX Nil ON VSCROLLBOX Nil'
		cFormContent += CRLF
		cFormContent += 'END WINDOW'
		cFormContent += CRLF

		If File ( Result )

			If MsgYesNo ( Result + ' ' + aMsgs [ 227 ] )
				SaveString ( Result , cFormContent  )
			Else
				Return (.F.)
			EndIf

		Else

			SaveString ( Result , cFormContent )

		EndIf

	Else

		cFormContent := ''
		cFormContent += 'DEFINE WINDOW TEMPLATE AT 138 , 235 WIDTH 550 HEIGHT 350 VIRTUAL WIDTH Nil VIRTUAL HEIGHT Nil TITLE "" ICON NIL MAIN CURSOR NIL ON INIT Nil ON RELEASE Nil ON INTERACTIVECLOSE Nil ON MOUSECLICK Nil ON MOUSEDRAG Nil ON MOUSEMOVE Nil ON SIZE Nil ON MAXIMIZE Nil ON MINIMIZE Nil ON PAINT Nil BACKCOLOR Nil NOTIFYICON NIL NOTIFYTOOLTIP NIL ON NOTIFYCLICK Nil ON GOTFOCUS Nil ON LOSTFOCUS Nil ON SCROLLUP Nil ON SCROLLDOWN Nil ON SCROLLLEFT Nil ON SCROLLRIGHT Nil ON HSCROLLBOX Nil ON VSCROLLBOX Nil'
		cFormContent += CRLF
		cFormContent += 'END WINDOW'
		cFormContent += CRLF

		If File ( Result )

			If MsgYesNo ( Result + ' ' + aMsgs [ 227 ] )

				SaveString ( Result , cFormContent )
	
			Else

				Return (.F.)
			
			EndIf

		Else

			SaveString ( Result , cFormContent )

		EndIf

	EndIf

	Project.List_2.AddItem ( Result )

	SortFormList( )

	SaveProject()

	Project.Tab_1.Value := 2

	Properties.Title := aMsgs [ 154 ]  + Result + ']'

	If _IsWindowDefined ( DesignForm )
		DoMethod ( DesignForm , 'Release' )
	EndIf


	_Open ( Result )

Return lRetVal