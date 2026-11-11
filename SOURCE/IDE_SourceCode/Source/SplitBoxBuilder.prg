PROCEDURE SplitBoxBuilder
local i
local l
local w

	if ! IsWindowDefined(&DesignForm)
		MsgStop ( aMsgs [ 086 ] ,'HMG IDE')
		RETURN
	EndIf

	if ! Empty ( _hmgide_CurrentToolBar )
		MsgStop ( aMsgs [ 171 ] ,'HMG IDE')
		RETURN
	endif

	DEFINE WINDOW 	spb	;
		AT	0,0	;
		WIDTH	400	;
		HEIGHT	290 + GetTitleHeight() + GetBorderHeight() + 3 ;
		TITLE	aMsgs [ 172 ] 	;
		MODAL

		DEFINE FRAME FRAME_1
			ROW	5
			COL	10
			WIDTH	260
			HEIGHT	205
			CAPTION	aMsgs [ 173 ] 
		END FRAME

		DEFINE GRID LIST_1
			ROW	27
			COL	23
			WIDTH	234
			HEIGHT	170
			WIDTHS	{ 110 , 110 }
			HEADERS { aMsgs [ 174 ]  , aMsgs [ 175 ]  }
			ONCHANGE IF ( this.cell ( this.value , 2 ) = 'Window' , spb.button_2c.enabled := .F. , spb.button_2c.enabled := .T. )
			ONDBLCLICK Sp6()
		END GRID

		DEFINE FRAME FRAME_2
			ROW	215
			COL	10
			WIDTH	260
			HEIGHT	65
			CAPTION	aMsgs [ 176 ] 
		END FRAME

		DEFINE CHECKBOX CHECK_1
			ROW	237
			COL	50
			CAPTION	'Bottom'
			VALUE	.F.
		END CHECKBOX

		DEFINE CHECKBOX CHECK_2
			ROW	237
			COL	150
			CAPTION	'Horizontal'
			VALUE	.F.
		END CHECKBOX

		DEFINE BUTTON BUTTON_1
			ROW	10
			COL	281
			CAPTION	aMsgs [ 177 ] 
			ACTION	Sp1()
		END BUTTON

		DEFINE BUTTON BUTTON_2
			ROW	40
			COL	281
			CAPTION	aMsgs [ 178 ] 
			ACTION	Sp2()
		END BUTTON

		DEFINE BUTTON BUTTON_2a
			ROW	70
			COL	281
			CAPTION	aMsgs [ 179 ] 
			ACTION	sp4()
		END BUTTON

		DEFINE BUTTON BUTTON_2b
			ROW	100
			COL	281
			CAPTION	aMsgs [ 180 ] 
			ACTION	Sp5()
		END BUTTON

		DEFINE BUTTON BUTTON_2c
			ROW	130
			COL	281
			CAPTION	aMsgs [ 181 ] 
			ACTION	Sp6()
		END BUTTON

		DEFINE BUTTON BUTTON_3
			ROW	222
			COL	281
			CAPTION	aMsgs [ 116 ]
			ACTION	( Sp3() , ThisWindow.Release )
		END BUTTON

		DEFINE BUTTON BUTTON_4
			ROW	252
			COL	281
			CAPTION	aMsgs [ 117 ]
			ACTION	ThisWindow.Release
		END BUTTON

	END WINDOW

	CENTER WINDOW spb 

	L := ALLTRIM ( MemoLine ( _hmgide_CurrentSplitBox , 1024 , 1 , 4 , .t. ) )

	IF 'BOTTOM' $ L
		SPB.CHECK_1.VALUE := .T.		
	ENDIF

	IF 'HORIZONTAL' $ L
		SPB.CHECK_2.VALUE := .T.		
	ENDIF

	for i := 1 to mlcount ( _hmgide_CurrentSplitBox )

		L := ALLTRIM ( MemoLine ( _hmgide_CurrentSplitBox , 1024 , i , 4 , .t. ) )

		if l = 'LOAD WINDOW '
			w := ALLTRIM ( HB_USUBSTR ( l , 13 , 255 ) )
			spb.list_1.additem ( { w , 'Window' } ) 
		elseif l = 'DEFINE BROWSE '
			w := ALLTRIM ( HB_USUBSTR ( l , 15 , 255 ) )
			spb.list_1.additem ( { w , 'Browse' } ) 
		elseif l = 'DEFINE COMBOBOX '
			w := ALLTRIM ( HB_USUBSTR ( l , 17 , 255 ) )
			spb.list_1.additem ( { w , 'ComboBox' } ) 
		elseif l = 'DEFINE EDITBOX '
			w := ALLTRIM ( HB_USUBSTR ( l , 16 , 255 ) )
			spb.list_1.additem ( { w , 'EditBox' } ) 
		elseif l = 'DEFINE GRID '
			w := ALLTRIM ( HB_USUBSTR ( l , 13 , 255 ) )
			spb.list_1.additem ( { w , 'Grid' } ) 
		elseif l = 'DEFINE LISTBOX '
			w := ALLTRIM ( HB_USUBSTR ( l , 16 , 255 ) )
			spb.list_1.additem ( { w , 'ListBox' } ) 
		elseif l = 'DEFINE RICHEDITBOX '
			w := ALLTRIM ( HB_USUBSTR ( l , 20 , 255 ) )
			spb.list_1.additem ( { w , 'RichEditBox' } ) 
		elseif l = 'DEFINE TOOLBAR '
			w := ALLTRIM ( HB_USUBSTR ( l , 16 , 255 ) )
			w := ALLTRIM ( HB_ULEFT ( w , HB_UAT( ' ' , w ) ) )
			spb.list_1.additem ( { w , 'ToolBar' } ) 
		elseif l = 'DEFINE TREE '
			w := ALLTRIM ( HB_USUBSTR ( l , 13 , 255 ) )
			w := ALLTRIM ( HB_ULEFT ( w , HB_UAT( ' ' , w ) ) )
			spb.list_1.additem ( { w , 'Tree' } ) 
		endif

	next i

	if spb.list_1.itemcount > 0
		spb.list_1.value := 1
	endif

	ACTIVATE WINDOW spb 

	DoMethod ( DesignForm , 'SetFocus' )

	DrawGrid()

RETURN


PROCEDURE sp6
local i

	i := spb.list_1.value

	if i == 0 
		RETURN
	endif

	if HMG_UPPER ( ALLTRIM ( spb.list_1.cell ( i , 2 ) ) ) == 'TOOLBAR'
		_spx_ToolBarBuilder( ALLTRIM ( spb.list_1.cell ( i , 1 ) ) )
	elseif HMG_UPPER ( ALLTRIM ( spb.list_1.cell ( i , 2 ) ) ) == 'WINDOW'
		RETURN
	else
		sp7 ( HMG_UPPER ( ALLTRIM ( spb.list_1.cell ( i , 2 ) ) ) , HMG_UPPER ( ALLTRIM ( spb.list_1.cell ( i , 1 ) ) ) )
	endif

RETURN

PROCEDURE sp7 ( cType , cName )

	DEFINE WINDOW sp7 ;
		AT 0 , 0 ;
		WIDTH 232 ;
		HEIGHT 205 + GetTitleHeight() + GetBorderHeight() + 1 ;
		TITLE aMsgs [ 182 ]  + cName + ']' ;
		MODAL ;
		NOSIZE 

		DEFINE TAB Tab_1 AT 4,3 WIDTH 220 HEIGHT 198 

			PAGE aMsgs [ 183 ] 

				DEFINE GRID Grid_1
					ROW	27
					COL	5
					WIDTH	208
					HEIGHT	164 
					HEADERS	{ aMsgs [ 184 ] ,aMsgs [ 185 ] }
					WIDTHS	{115,72}
					ITEMS	{ {'',''},{'',''},{'',''},{'',''},{'',''} }
					FONTNAME 'Arial'
					FONTSIZE 9
					ON DBLCLICK sp8( cName , cType )
					TOOLTIP aMsgs [ 186 ] 
				END GRID

			END PAGE

			PAGE aMsgs [ 187 ] 

				DEFINE GRID Grid_2
					ROW	27
					COL	5
					WIDTH	208
					HEIGHT	164 
					HEADERS	{ aMsgs [ 197 ] , aMsgs [ 198 ] }
					WIDTHS	{115,72}
					ITEMS	{ {'',''},{'',''},{'',''},{'',''},{'',''} }
					FONTNAME 'Arial'
					FONTSIZE 9
					ON DBLCLICK Sp8( cName , cType )
					TOOLTIP aMsgs [ 186 ]  
				END GRID

			END PAGE

		END TAB

	END WINDOW

	If	cType == 'BROWSE'

		sp7.Grid_1.DeleteAllItems

		sp7.Grid_1.AddItem ( {'AllowAppend', __MVGET ( cName + 'AllowAppend' ) } )
		sp7.Grid_1.AddItem ( {'AllowDelete', __MVGET ( cName + 'AllowDelete' ) } )
		sp7.Grid_1.AddItem ( {'AllowEdit', __MVGET ( cName + 'AllowEdit' ) } )
		sp7.Grid_1.AddItem ( {'BackColor', __MVGET ( cName + 'BackColor' ) } )
		sp7.Grid_1.AddItem ( {'Break', __MVGET ( cName + 'Break' ) } )
		sp7.Grid_1.AddItem ( {'Col', __MVGET ( cName + 'Col' ) } )
		sp7.Grid_1.AddItem ( {'DynamicBackColor', __MVGET ( cName + 'DynamicBackColor' ) } )
		sp7.Grid_1.AddItem ( {'DynamicForeColor', __MVGET ( cName + 'DynamicForeColor' ) } )
		sp7.Grid_1.AddItem ( {'Fields',  __MVGET ( cName + 'Fields' ) } )
		sp7.Grid_1.AddItem ( {'FontBold', __MVGET ( cName + 'FontBold' ) } )
		sp7.Grid_1.AddItem ( {'FontColor', __MVGET ( cName + 'FontColor' ) } )
		sp7.Grid_1.AddItem ( {'FontItalic', __MVGET ( cName + 'FontItalic' ) } )
		sp7.Grid_1.AddItem ( {'FontName', __MVGET ( cName + 'FontName' ) } )
		sp7.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( cName + 'FontUnderLine' ) } )
		sp7.Grid_1.AddItem ( {'FontSize', __MVGET ( cName + 'FontSize' ) } )
		sp7.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( cName + 'FontStrikeOut' ) } )
		sp7.Grid_1.AddItem ( {'Format', __MVGET ( cName + 'Format' ) } )
		sp7.Grid_1.AddItem ( {'Headers',  __MVGET ( cName + 'Headers' ) } )
		sp7.Grid_1.AddItem ( {'Height',  __MVGET ( cName + 'Height' ) } )
		sp7.Grid_1.AddItem ( {'HelpId', __MVGET ( cName + 'HelpId' ) } )
		sp7.Grid_1.AddItem ( {'Image',  __MVGET ( cName + 'Image' ) } )
		sp7.Grid_1.AddItem ( {'InputMask',  __MVGET ( cName + 'InputMask' ) } )
		sp7.Grid_1.AddItem ( {'Justify',  __MVGET ( cName + 'Justify' ) } )
		sp7.Grid_1.AddItem ( {'Lines', __MVGET ( cName + 'Lines' ) } )
		sp7.Grid_1.AddItem ( {'Lock', __MVGET ( cName + 'Lock' ) } )
		sp7.Grid_1.AddItem ( {'Name', cName } )
		sp7.Grid_1.AddItem ( {'ReadOnlyFields',  __MVGET ( cName + 'ReadOnlyFields' ) } )
		sp7.Grid_1.AddItem ( {'Row',  __MVGET ( cName + 'Row' ) } )
		sp7.Grid_1.AddItem ( {'Valid', __MVGET ( cName + 'Valid' ) } )
		sp7.Grid_1.AddItem ( {'ValidMessages', __MVGET ( cName + 'ValidMessages' ) } )
		sp7.Grid_1.AddItem ( {'Value',  __MVGET ( cName + 'Value' ) } )
		sp7.Grid_1.AddItem ( {'vScrollBar',  __MVGET ( cName + 'vScrollBar' ) } )
		sp7.Grid_1.AddItem ( {'ToolTip', __MVGET ( cName + 'ToolTip' ) } )
		sp7.Grid_1.AddItem ( {'When', __MVGET ( cName + 'When' ) } )
		sp7.Grid_1.AddItem ( {'Width',  __MVGET ( cName + 'Width' ) } )
		sp7.Grid_1.AddItem ( {'Widths',  __MVGET ( cName + 'Widths' ) } )
		sp7.Grid_1.AddItem ( {'WorkArea',  __MVGET ( cName + 'WorkArea' ) } )

		sp7.Grid_2.DeleteAllItems

		sp7.Grid_2.AddItem ( {'OnChange', __MVGET ( cName + 'OnChange' ) } )
		sp7.Grid_2.AddItem ( {'OnDblClick', __MVGET ( cName + 'OnDblClick' ) } )
		sp7.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( cName + 'OnGotFocus' ) } )
		sp7.Grid_2.AddItem ( {'OnHeadClick', __MVGET ( cName + 'OnHeadClick' ) } )
		sp7.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( cName + 'OnLostFocus' ) } )

		elseIf	cType == 'COMBOBOX'

		sp7.Grid_1.DeleteAllItems
		sp7.Grid_1.AddItem ( {'Break', __MVGET ( cName + 'Break' ) } )
		sp7.Grid_1.AddItem ( {'Col', __MVGET ( cName + 'Col' ) } )
		sp7.Grid_1.AddItem ( {'DisplayEdit', __MVGET ( cName + 'DisplayEdit' ) } )
		sp7.Grid_1.AddItem ( {'FontBold', __MVGET ( cName + 'FontBold' ) } )
		sp7.Grid_1.AddItem ( {'FontItalic', __MVGET ( cName + 'FontItalic' ) } )
		sp7.Grid_1.AddItem ( {'FontName', __MVGET ( cName + 'FontName' ) } )
		sp7.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( cName + 'FontUnderLine' ) } )
		sp7.Grid_1.AddItem ( {'FontSize', __MVGET ( cName + 'FontSize' ) } )
		sp7.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( cName + 'FontStrikeOut' ) } )
		sp7.Grid_1.AddItem ( {'Height',  __MVGET ( cName + 'Height' ) } )
		sp7.Grid_1.AddItem ( {'HelpId', __MVGET ( cName + 'HelpId' ) } )
		sp7.Grid_1.AddItem ( {'Items',  __MVGET ( cName + 'Items' ) } )
		sp7.Grid_1.AddItem ( {'ItemSource',  __MVGET ( cName + 'ItemSource' ) } )
		sp7.Grid_1.AddItem ( {'Name',cName } )
		sp7.Grid_1.AddItem ( {'Row',  __MVGET ( cName + 'Row' ) } )
		sp7.Grid_1.AddItem ( {'Sort', __MVGET ( cName + 'Sort' ) } )
		sp7.Grid_1.AddItem ( {'TabStop', __MVGET ( cName + 'TabStop' ) } )
		sp7.Grid_1.AddItem ( {'ToolTip', __MVGET ( cName + 'ToolTip' ) } )
		sp7.Grid_1.AddItem ( {'Value',  __MVGET ( cName + 'Value' ) } )
		sp7.Grid_1.AddItem ( {'ValueSource',  __MVGET ( cName + 'ValueSource' ) } )
		sp7.Grid_1.AddItem ( {'Visible', __MVGET ( cName + 'Visible' ) } )
		sp7.Grid_1.AddItem ( {'Width',  __MVGET ( cName + 'Width' ) } )

		sp7.Grid_2.DeleteAllItems
		sp7.Grid_2.AddItem ( {'OnChange', __MVGET ( cName + 'OnChange' ) } )
		sp7.Grid_2.AddItem ( {'OnDisplayChange', __MVGET ( cName + 'OnDisplayChange' ) } )
		sp7.Grid_2.AddItem ( {'OnEnter', __MVGET ( cName + 'OnEnter' ) } )
		sp7.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( cName + 'OnGotFocus' ) } )
		sp7.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( cName + 'OnLostFocus' ) } )

		elseIf	cType == 'EDITBOX'

		sp7.Grid_1.DeleteAllItems
		sp7.Grid_1.AddItem ( {'BackColor', __MVGET ( cName + 'BackColor' ) } )
		sp7.Grid_1.AddItem ( {'Break', __MVGET ( cName + 'Break' ) } )
		sp7.Grid_1.AddItem ( {'Col', __MVGET ( cName + 'Col' ) } )
		sp7.Grid_1.AddItem ( {'Field', __MVGET ( cName + 'Field' ) } )
		sp7.Grid_1.AddItem ( {'FontBold', __MVGET ( cName + 'FontBold' ) } )
		sp7.Grid_1.AddItem ( {'FontColor', __MVGET ( cName + 'FontColor' ) } )
		sp7.Grid_1.AddItem ( {'FontItalic', __MVGET ( cName + 'FontItalic' ) } )
		sp7.Grid_1.AddItem ( {'FontName', __MVGET ( cName + 'FontName' ) } )
		sp7.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( cName + 'FontUnderLine' ) } )
		sp7.Grid_1.AddItem ( {'FontSize', __MVGET ( cName + 'FontSize' ) } )
		sp7.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( cName + 'FontStrikeOut' ) } )
		sp7.Grid_1.AddItem ( {'Height',  __MVGET ( cName + 'Height' ) } )
		sp7.Grid_1.AddItem ( {'HelpId', __MVGET ( cName + 'HelpId' ) } )
		sp7.Grid_1.AddItem ( {'HScrollBar', __MVGET ( cName + 'hScrollBar' ) } )
		sp7.Grid_1.AddItem ( {'MaxLength', __MVGET ( cName + 'MaxLength' ) } )
		sp7.Grid_1.AddItem ( {'Name',cName } )
		sp7.Grid_1.AddItem ( {'ReadOnly',  __MVGET ( cName + 'ReadOnly' ) } )
		sp7.Grid_1.AddItem ( {'Row',  __MVGET ( cName + 'Row' ) } )
		sp7.Grid_1.AddItem ( {'TabStop', __MVGET ( cName + 'TabStop' ) } )
		sp7.Grid_1.AddItem ( {'ToolTip', __MVGET ( cName + 'ToolTip' ) } )
		sp7.Grid_1.AddItem ( {'Value',  __MVGET ( cName + 'Value' ) } )
		sp7.Grid_1.AddItem ( {'Visible', __MVGET ( cName + 'Visible' ) } )
		sp7.Grid_1.AddItem ( {'VScrollBar', __MVGET ( cName + 'VScrollBar' ) } )
		sp7.Grid_1.AddItem ( {'Width',  __MVGET ( cName + 'Width' ) } )

		sp7.Grid_2.DeleteAllItems
		sp7.Grid_2.AddItem ( {'OnChange', __MVGET ( cName + 'OnChange' ) } )
		sp7.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( cName + 'OnGotFocus' ) } )
		sp7.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( cName + 'OnLostFocus' ) } )

		elseIf	cType == 'LISTBOX'

		sp7.Grid_1.DeleteAllItems
		sp7.Grid_1.AddItem ( {'BackColor', __MVGET ( cName + 'BackColor' ) } )
		sp7.Grid_1.AddItem ( {'Break', __MVGET ( cName + 'Break' ) } )
		sp7.Grid_1.AddItem ( {'Col', __MVGET ( cName + 'Col' ) } )
		sp7.Grid_1.AddItem ( {'FontBold', __MVGET ( cName + 'FontBold' ) } )
		sp7.Grid_1.AddItem ( {'FontColor', __MVGET ( cName + 'FontColor' ) } )
		sp7.Grid_1.AddItem ( {'FontItalic', __MVGET ( cName + 'FontItalic' ) } )
		sp7.Grid_1.AddItem ( {'FontName', __MVGET ( cName + 'FontName' ) } )
		sp7.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( cName + 'FontUnderLine' ) } )
		sp7.Grid_1.AddItem ( {'FontSize', __MVGET ( cName + 'FontSize' ) } )
		sp7.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( cName + 'FontStrikeOut' ) } )
		sp7.Grid_1.AddItem ( {'Height',  __MVGET ( cName + 'Height' ) } )
		sp7.Grid_1.AddItem ( {'HelpId', __MVGET ( cName + 'HelpId' ) } )
		sp7.Grid_1.AddItem ( {'Items',  __MVGET ( cName + 'Items' ) } )
		sp7.Grid_1.AddItem ( {'MultiSelect',  __MVGET ( cName + 'MultiSelect' ) } )
		sp7.Grid_1.AddItem ( {'Name',cName } )
		sp7.Grid_1.AddItem ( {'Row',  __MVGET ( cName + 'Row' ) } )
		sp7.Grid_1.AddItem ( {'Sort', __MVGET ( cName + 'Sort' ) } )
		sp7.Grid_1.AddItem ( {'TabStop', __MVGET ( cName + 'TabStop' ) } )
		sp7.Grid_1.AddItem ( {'ToolTip', __MVGET ( cName + 'ToolTip' ) } )
		sp7.Grid_1.AddItem ( {'Value',  __MVGET ( cName + 'Value' ) } )
		sp7.Grid_1.AddItem ( {'Visible', __MVGET ( cName + 'Visible' ) } )
		sp7.Grid_1.AddItem ( {'Width',  __MVGET ( cName + 'Width' ) } )

		sp7.Grid_2.DeleteAllItems
		sp7.Grid_2.AddItem ( {'OnChange', __MVGET ( cName + 'OnChange' ) } )
		sp7.Grid_2.AddItem ( {'OnDblClick', __MVGET ( cName + 'OnDblClick' ) } )
		sp7.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( cName + 'OnGotFocus' ) } )
		sp7.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( cName + 'OnLostFocus' ) } )

		elseIf	cType == 'GRID'

		sp7.Grid_1.DeleteAllItems
		sp7.Grid_1.AddItem ( {'AllowEdit', __MVGET ( cName + 'AllowEdit' ) } )
		sp7.Grid_1.AddItem ( {'BackColor', __MVGET ( cName + 'BackColor' ) } )
		sp7.Grid_1.AddItem ( {'Break', __MVGET ( cName + 'Break' ) } )
		sp7.Grid_1.AddItem ( {'Col', __MVGET ( cName + 'Col' ) } )
		sp7.Grid_1.AddItem ( {'ColumnControls', __MVGET ( cName + 'ColumnControls' ) } )
		sp7.Grid_1.AddItem ( {'ColumnValid', __MVGET ( cName + 'ColumnValid' ) } )
		sp7.Grid_1.AddItem ( {'ColumnWhen', __MVGET ( cName + 'ColumnWhen' ) } )
		sp7.Grid_1.AddItem ( {'DynamicBackColor', __MVGET ( cName + 'DynamicBackColor' ) } )
		sp7.Grid_1.AddItem ( {'DynamicForeColor', __MVGET ( cName + 'DynamicForeColor' ) } )
		sp7.Grid_1.AddItem ( {'FontBold', __MVGET ( cName + 'FontBold' ) } )
		sp7.Grid_1.AddItem ( {'FontColor', __MVGET ( cName + 'FontColor' ) } )
		sp7.Grid_1.AddItem ( {'FontItalic', __MVGET ( cName + 'FontItalic' ) } )
		sp7.Grid_1.AddItem ( {'FontName', __MVGET ( cName + 'FontName' ) } )
		sp7.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( cName + 'FontUnderLine' ) } )
		sp7.Grid_1.AddItem ( {'FontSize', __MVGET ( cName + 'FontSize' ) } )
		sp7.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( cName + 'FontStrikeOut' ) } )
		sp7.Grid_1.AddItem ( {'Headers',  __MVGET ( cName + 'Headers' ) } )
		sp7.Grid_1.AddItem ( {'Height',  __MVGET ( cName + 'Height' ) } )
		sp7.Grid_1.AddItem ( {'HelpId',  __MVGET ( cName + 'HelpId' ) } )
		sp7.Grid_1.AddItem ( {'Image',  __MVGET ( cName + 'Image' ) } )
		sp7.Grid_1.AddItem ( {'ItemCount',  __MVGET ( cName + 'ItemCount' ) } )
		sp7.Grid_1.AddItem ( {'Items',  __MVGET ( cName + 'Items' ) } )
		sp7.Grid_1.AddItem ( {'Justify',  __MVGET ( cName + 'Justify' ) } )
		sp7.Grid_1.AddItem ( {'Lines', __MVGET ( cName + 'Lines' ) } )
		sp7.Grid_1.AddItem ( {'MultiSelect',  __MVGET ( cName + 'MultiSelect' ) } )
		sp7.Grid_1.AddItem ( {'Name',cName } )
		sp7.Grid_1.AddItem ( {'Row',  __MVGET ( cName + 'Row' ) } )
		sp7.Grid_1.AddItem ( {'ShowHeaders', __MVGET ( cName + 'ShowHeaders' ) } )
		sp7.Grid_1.AddItem ( {'ToolTip', __MVGET ( cName + 'ToolTip' ) } )
		sp7.Grid_1.AddItem ( {'Value',  __MVGET ( cName + 'Value' ) } )
		sp7.Grid_1.AddItem ( {'Virtual',  __MVGET ( cName + 'Virtual' ) } )
		sp7.Grid_1.AddItem ( {'Width',  __MVGET ( cName + 'Width' ) } )
		sp7.Grid_1.AddItem ( {'Widths',  __MVGET ( cName + 'Widths' ) } )

		sp7.Grid_2.DeleteAllItems
		sp7.Grid_2.AddItem ( {'OnChange', __MVGET ( cName + 'OnChange' ) } )
		sp7.Grid_2.AddItem ( {'OnDblClick', __MVGET ( cName + 'OnDblClick' ) } )
		sp7.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( cName + 'OnGotFocus' ) } )
		sp7.Grid_2.AddItem ( {'OnHeadClick', __MVGET ( cName + 'OnHeadClick' ) } )
		sp7.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( cName + 'OnLostFocus' ) } )
		sp7.Grid_2.AddItem ( {'OnQueryData', __MVGET ( cName + 'OnQueryData' ) } )

		elseIf	cType == 'RICHEDITBOX'

		sp7.Grid_1.DeleteAllItems

		sp7.Grid_1.AddItem ( {'BackColor', __MVGET ( cName + 'BackColor' ) } )
		sp7.Grid_1.AddItem ( {'Break', __MVGET ( cName + 'Break' ) } )
		sp7.Grid_1.AddItem ( {'Col', __MVGET ( cName + 'Col' ) } )
		sp7.Grid_1.AddItem ( {'Field', __MVGET ( cName + 'Field' ) } )
		sp7.Grid_1.AddItem ( {'FontBold', __MVGET ( cName + 'FontBold' ) } )
		sp7.Grid_1.AddItem ( {'FontItalic', __MVGET ( cName + 'FontItalic' ) } )
		sp7.Grid_1.AddItem ( {'FontName', __MVGET ( cName + 'FontName' ) } )
		sp7.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( cName + 'FontUnderLine' ) } )
		sp7.Grid_1.AddItem ( {'FontSize', __MVGET ( cName + 'FontSize' ) } )
		sp7.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( cName + 'FontStrikeOut' ) } )
		sp7.Grid_1.AddItem ( {'Height',  __MVGET ( cName + 'Height' ) } )
		sp7.Grid_1.AddItem ( {'HelpId', __MVGET ( cName + 'HelpId' ) } )
		sp7.Grid_1.AddItem ( {'MaxLength', __MVGET ( cName + 'MaxLength' ) } )
		sp7.Grid_1.AddItem ( {'Name',cName } )
		sp7.Grid_1.AddItem ( {'ReadOnly',  __MVGET ( cName + 'ReadOnly' ) } )
		sp7.Grid_1.AddItem ( {'Row',  __MVGET ( cName + 'Row' ) } )
		sp7.Grid_1.AddItem ( {'TabStop', __MVGET ( cName + 'TabStop' ) } )
		sp7.Grid_1.AddItem ( {'ToolTip', __MVGET ( cName + 'ToolTip' ) } )
		sp7.Grid_1.AddItem ( {'Value',  __MVGET ( cName + 'Value' ) } )
		sp7.Grid_1.AddItem ( {'Visible', __MVGET ( cName + 'Visible' ) } )
		sp7.Grid_1.AddItem ( {'Width',  __MVGET ( cName + 'Width' ) } )

		sp7.Grid_2.DeleteAllItems
		sp7.Grid_2.AddItem ( {'OnChange', __MVGET ( cName + 'OnChange' ) } )
		sp7.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( cName + 'OnGotFocus' ) } )
		sp7.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( cName + 'OnLostFocus' ) } )

		elseIf	cType == 'TREE'

		sp7.Grid_1.DeleteAllItems
		sp7.Grid_1.AddItem ( {'Break', __MVGET ( cName + 'Break' ) } )
		sp7.Grid_1.AddItem ( {'Col', __MVGET ( cName + 'Col' ) } )
		sp7.Grid_1.AddItem ( {'FontBold', __MVGET ( cName + 'FontBold' ) } )
		sp7.Grid_1.AddItem ( {'FontItalic', __MVGET ( cName + 'FontItalic' ) } )
		sp7.Grid_1.AddItem ( {'FontName', __MVGET ( cName + 'FontName' ) } )
		sp7.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( cName + 'FontUnderLine' ) } )
		sp7.Grid_1.AddItem ( {'FontSize', __MVGET ( cName + 'FontSize' ) } )
		sp7.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( cName + 'FontStrikeOut' ) } )
		sp7.Grid_1.AddItem ( {'Height',  __MVGET ( cName + 'Height' ) } )
		sp7.Grid_1.AddItem ( {'HelpId', __MVGET ( cName + 'HelpId' ) } )
		sp7.Grid_1.AddItem ( {'ItemIds', __MVGET ( cName + 'ItemIds' ) } )
		sp7.Grid_1.AddItem ( {'ItemImages', __MVGET ( cName + 'ItemImages' ) } )
		sp7.Grid_1.AddItem ( {'Name',cName } )
		sp7.Grid_1.AddItem ( {'NodeImages', __MVGET ( cName + 'NodeImages' ) } )
		sp7.Grid_1.AddItem ( {'RootButton', __MVGET ( cName + 'RootButton' ) } )
		sp7.Grid_1.AddItem ( {'Row',  __MVGET ( cName + 'Row' ) } )
		sp7.Grid_1.AddItem ( {'ToolTip', __MVGET ( cName + 'ToolTip' ) } )
		sp7.Grid_1.AddItem ( {'Value',  __MVGET ( cName + 'Value' ) } )
		sp7.Grid_1.AddItem ( {'Width',  __MVGET ( cName + 'Width' ) } )

		sp7.Grid_2.DeleteAllItems
		sp7.Grid_2.AddItem ( {'OnChange', __MVGET ( cName + 'OnChange' ) } )
		sp7.Grid_2.AddItem ( {'OnDblClick', __MVGET ( cName + 'OnDblClick' ) } )
		sp7.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( cName + 'OnGotFocus' ) } )
		sp7.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( cName + 'OnLostFocus' ) } )

	endif

	CENTER WINDOW sp7

	ACTIVATE WINDOW sp7

RETURN

PROCEDURE sp8 ( cControlName , cType )
Local cName , cValue , Result
Local PropertyName
Local SelectedControlType
Local aRow

	cName := this.cell ( this.value , 1 )
	cValue := this.cell ( this.value , 2 )

	if cName = 'Name' .or. cName = 'Col' .or. cName = 'Row'
		PlayHand()
		RETURN
	endif

	PropertyName := ALLTRIM(HMG_UPPER(cName))

	SelectedControlType := ALLTRIM(HMG_UPPER(cType))

	aRow := { cName , cValue }

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
		PropertyName == 'READONLY' ;
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
		PropertyName == 'VIRTUAL SIZED' ;
		.Or. ;
		PropertyName == 'ITEMIDS' ;
		.Or. ;
		( PropertyName == 'VALUE' .And. SelectedControlType == 'CHECKBOX' ) ;
		.Or. ;
		( PropertyName == 'VALUE' .And. SelectedControlType == 'CHECKBUTTON' )

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 188 ]  , aRow [1] + ':' , { '.T.' , '.F.' } , aRow [2] ) )

	ElseIf	PropertyName == 'CASECONVERT' 

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 188 ] , aRow [1] + ':' , { 'LOWER' , 'NONE' , 'UPPER' } , aRow [2] ) )

	ElseIf	PropertyName == 'ALIGNMENT' 

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 188 ] , aRow [1] + ':' , { 'LEFT' , 'RIGHT' , 'CENTER' } , aRow [2] ) )

	ElseIf	PropertyName == 'ROW' ;
		.Or. ;
		PropertyName == 'COL' ;
		.Or. ;
		PropertyName == 'WIDTH' ;
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
		( PropertyName == 'VALUE' .And. SelectedControlType == 'GRID' ) ;
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

		Result := ALLTRIM ( PickNumericPropertyValue ( 'Edit' , aRow [1] + ':' , aRow [2] ) )

	ElseIf PropertyName == 'WINDOWTYPE'

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 188 ] , aRow [1] + ':' , { 'CHILD' , 'MAIN' , 'MODAL' , 'SPLITCHILD' , 'STANDARD' , 'PANEL' } , aRow [2] ) )

	ElseIf PropertyName == 'HELPBUTTON'

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 188 ] , aRow [1] + ':' , { 'CHILD' , 'MAIN' , 'MODAL' , 'SPLITCHILD' , 'STANDARD' , 'PANEL' } , aRow [2] ) )

	ElseIf PropertyName == 'DATATYPE'

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 188 ] , aRow [1] + ':' , { 'CHARACTER' , 'DATE' , 'NUMERIC' } , aRow [2] ) )

	ElseIf PropertyName == 'ORIENTATION'

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 188 ] , aRow [1] + ':' , { 'HORIZONTAL' , 'VERTICAL' } , aRow [2] ) )

	ElseIf PropertyName == 'TICKMARKS' .And. ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlname + 'Orientation' ) ) ) == 'HORIZONTAL' 

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 188 ] , aRow [1] + ':' , { 'BOTH' , 'BOTTOM' ,  'NONE' , 'TOP' } , aRow [2] ) )

	ElseIf PropertyName == 'TICKMARKS' .And. ALLTRIM ( HMG_UPPER ( __MVGET ( SelectedControlname + 'Orientation' ) ) ) == 'VERTICAL'  

		Result := ALLTRIM ( PickPropertyValue ( aMsgs [ 188 ] , aRow [1] + ':' , { 'BOTH' , 'LEFT' , 'NONE' , 'RIGHT' } , aRow [2] ) )

	ElseIf PropertyName == 'BACKCOLOR'

		Result := PickColorValue()

	ElseIf PropertyName == 'FONTCOLOR'

		Result := PickColorValue()

	ElseIf PropertyName == 'FORECOLOR'

		Result := PickColorValue()

	Else

		Result := ALLTRIM ( PickCharacterPropertyValue ( aMsgs [ 188 ] , aRow [1] + ':' , aRow [2] ) )

	EndIf

	if _HMG_SYSDATA [ 257 ] == .T.
		RETURN
	else
		this.cell ( this.value , 2 ) := ALLTRIM ( Result )
		__MVPUT ( cControlName + cName , Result )

	endif

RETURN

PROCEDURE Sp1
local n
local i
Local aTemp
Local t
Local cNewToolBar

	aTemp := GetChild()

	n := aTemp [2]
	t := aTemp [1]

	if t == 0
		RETURN
	endif

	if t == 1

		if HB_URIGHT ( HMG_UPPER ( n ) , 4 ) == '.FMG'
			n := HB_ULEFT ( n , HMG_LEN (n) - 4 )
		endif

		for i := 1 to spb.list_1.itemcount
			if ALLTRIM(HMG_UPPER( spb.list_1.Cell ( i , 2 ) ) ) == 'WINDOW'
				if ALLTRIM(HMG_UPPER(n)) == ALLTRIM(HMG_UPPER( spb.list_1.Cell ( i , 1 ) ) )
					msgstop( aMsgs [ 189 ] ,'HMG IDE')
					RETURN
				endif
			endif
		next i 

		spb.list_1.additem ( { n , 'Window' } )

	elseif t == 2

		if ! iscontrolinsplit(n)

			spb.list_1.additem ( { n , 'Browse' } )

			* Browse Properties

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'AllowAppend' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'AllowAppend' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'AllowDelete' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'AllowDelete' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'AllowEdit' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'AllowEdit' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'BackColor' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'BackColor' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'DynamicBackColor' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'DynamicBackColor' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'DynamicForeColor' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'DynamicForeColor' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Fields' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Fields' , "{''}" ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontColor' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontColor' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Fontname' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName' , 'Arial' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' , '9' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Format' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Format' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Headers' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Headers' , "{''}" ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' , '120' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Image' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Image' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'InputMask' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'InputMask' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Justify' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Justify' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Lines' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Lines' , '.T.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Lock' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Lock' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Name' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Name' , n ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ReadOnlyFields' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ReadOnlyFields' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Valid' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Valid' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ValidMessages' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ValidMessages' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' , '0' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'vScrollBar' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'vScrollBar' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' , '' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'When' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'When' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' , '120' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Widths' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Widths' , '{0}' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'WorkArea' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'WorkArea' , 'Nil' ) 

			* Browse Events

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnDblClick' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnDblClick' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnHeadClick' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnHeadClick' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' , 'Nil' ) 

		endif

	elseif t == 3

		if ! iscontrolinsplit(n)

			spb.list_1.additem ( { n , 'ComboBox' } )

			* ComboBox Properties

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'DisplayEdit' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'DisplayEdit' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName' , 'Arial' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' , '9' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' , '100' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Items' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Items' , '{""}' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ItemSource' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ItemSource' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Name' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Name' , n ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Sort' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Sort' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'TabStop' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'TabStop' , '.T.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' , '' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' , '0' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ValueSource' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ValueSource' , '' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Visible' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Visible' , '.T.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' , '100' ) 

			* ComboBox Events

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnDisplayChange' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnDisplayChange' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnEnter' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnEnter' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' , 'Nil' ) 

		endif

	elseif t == 4

		if ! iscontrolinsplit(n)

			spb.list_1.additem ( { n , 'EditBox' } )

			* EditBox Properties

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'BackColor' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'BackColor' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Field' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Field' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontColor' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontColor' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName' , 'Arial' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' , '9' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' , '120' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'hScrollBar' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'hScrollBar' , '.T.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'MaxLength' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'MaxLength' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Name' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Name' , n ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ReadOnly' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ReadOnly' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'TabStop' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'TabStop' , '.T.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' , '' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' , '' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Visible' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Visible' , '.T.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'vScrollBar' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'vScrollBar' , '.T.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' , '120' ) 

			* EditBox Events

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' , 'Nil' ) 

		endif

	elseif t == 5

		if ! iscontrolinsplit(n)

			spb.list_1.additem ( { n , 'ListBox' } )

			* ListBox Properties

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'BackColor' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'BackColor' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontColor' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontColor' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName' , 'Arial' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' , '9' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' , '100' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Items' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Items' , '{""}' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'MultiSelect' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'MultiSelect' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Name' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Name' , n ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Sort' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Sort' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'TabStop' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'TabStop' , '.T.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' , '' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' , '0' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Visible' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Visible' , '.T.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' , '100' ) 

			* ListBox Events

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnDblClick' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnDblClick' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' , 'Nil' ) 

		endif

	elseif t == 6

		if ! iscontrolinsplit(n)

			spb.list_1.additem ( { n , 'Grid' } )

			* Grid Properties

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'AllowEdit' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'AllowEdit' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'BackColor' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'BackColor' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ColumnControls' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ColumnControls' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ColumnValid' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ColumnValid' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ColumnWhen' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ColumnWhen' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'DynamicBackColor' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'DynamicBackColor' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'DynamicForeColor' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'DynamicForeColor' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontColor' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontColor' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName' , 'Arial' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' , '9' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Headers' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Headers' , "{''}" ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' , '120' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Image' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Image' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ItemCount' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ItemCount' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Items' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Items' , '{ {""} }' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Justify' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Justify' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Lines' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Lines' , '.T.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'MultiSelect' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'MultiSelect' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Name' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Name' , n ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ShowHeaders' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ShowHeaders' , '.T.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' , '' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' , '0' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Virtual' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Virtual' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' , '120' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Widths' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Widths' , '{ 0 }' ) 

			* Grid Events

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnDblClick' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnDblClick' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnHeadClick' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnHeadClick' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnQueryData' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnQueryData' , 'Nil' ) 

		endif

	elseif t == 7

		if ! iscontrolinsplit(n)

			spb.list_1.additem ( { n , 'RichEditBox' } )

			* RichEditBox Properties

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'BackColor' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'BackColor' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Field' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Field' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Fontname' , 'Arial' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' , '9' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' , '120' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'MaxLength' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'MaxLength' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ReadOnly' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ReadOnly' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'TabStop' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'TabStop' , '.T.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' , '' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' , '' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Visible' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Visible' , '.T.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' , '120' ) 

			* RichEditBox Events

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' , 'Nil' ) 

		endif

	elseif t == 8

		if ! iscontrolinsplit(n)

			spb.list_1.additem ( { n , 'ToolBar' } )

			cNewToolBar := ''
			cNewToolBar := cNewToolBar + Space(8) + 'DEFINE TOOLBAR ' + N + ' BUTTONSIZE 64,64 FONT "Arial" SIZE 9 FLAT ' + CRLF
			cNewToolBar := cNewToolBar + Space (12) + 'BUTTON ' + N + '_Btn1' + ' CAPTION "" PICTURE "MINIGUI_EDIT_NEW" ACTION Nil TOOLTIP ""'+ CRLF
			cNewToolBar := cNewToolBar + Space (8) + 'END TOOLBAR' + CRLF
		
			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'SpxToolBar' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'SpxToolBar' , cNewToolBar ) 

		endif
		
	elseif t == 9

		if ! iscontrolinsplit(n)

			spb.list_1.additem ( { n , 'Tree' } )

			* Tree Properties

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName' , 'Arial' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' , '9' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' , '120' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ItemIds' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ItemIds' , '.F.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ItemImages' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ItemImages' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'NodeImages' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'NodeImages' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'RootButton' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'RootButton' , '.T.' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' , '' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' , '0' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' , '120' ) 

			* Tree Events

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnDblClick' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnDblClick' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' , 'Nil' ) 

			__MVPUBLIC ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' ) 
			__MVPUT ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' , 'Nil' ) 

		endif

	endif

RETURN

FUNCTION iscontrolinsplit(n)
local i

	for i := 1 to spb.list_1.itemcount
		if ALLTRIM(HMG_UPPER( spb.list_1.Cell ( i , 2 ) ) ) != 'WINDOW'
			if ALLTRIM(HMG_UPPER(n)) == ALLTRIM(HMG_UPPER( spb.list_1.Cell ( i , 1 ) ) )
				msgstop( aMsgs [ 190 ] ,'HMG IDE')
				RETURN .t.
			endif
		endif
	next i 

RETURN .f.

FUNCTION GetChild()
local retval := { 0 , '' }

	define window sp9 at 0,0 width 302 height 395 + If ( IsAppThemed() , 7 , 0 ) + if( IsVista()  .And. IsAppThemed() , 6 , 0 ) title aMsgs [ 194 ] modal

		define frame frame1
			row 10
			col 10
			width 270
			height 250
			caption aMsgs [ 191 ] 
		end frame

		define radiogroup radio1
			row 26
			col 40
			options { 'Window' , 'Browse' , 'ComboBox' , 'EditBox' , 'ListBox' , 'Grid' , 'RichEditBox' , 'ToolBar' , 'Tree' }
			OnChange sp9.text1.setfocus
			value 1
		end radiogroup

		define frame frame2
			row 265
			col 10
			width 270
			height 55
			caption aMsgs [ 174 ] 
		end frame

		define textbox text1
			row 284
			col 22
			width 241
			value ''
		end textbox

		define button ok
			row 330
			col 45
			caption aMsgs [ 116 ]
			action if ( empty ( sp9.text1.value ) , ( MsgStop( aMsgs [ 192 ] ,'HMG IDE') , sp9.text1.setfocus ) , ( RetVal := { sp9.radio1.value , sp9.text1.value } , ThisWindow.Release ) )
		end button

		define button cancel
			row 330
			col 155
			caption aMsgs [ 117 ]
			action ( RetVal := { 0 , '' } , ThisWindow.Release )
		end button

	end window

	center window sp9

	sp9.text1.setfocus

	activate window sp9

RETURN retval

PROCEDURE Sp2
local i

	i := spb.list_1.value

	if i == 0
		msgstop( aMsgs [ 193 ] ,'HMG IDE')
		RETURN
	endif

	if ! msgyesno( aMsgs [ 099 ] ,'HMG IDE')
		RETURN
	endif
		
	spb.list_1.deleteitem (i)

RETURN

PROCEDURE Sp3
local c := ''
local i
local n

	if spb.list_1.itemcount == 0
		_hmgide_CurrentSplitBox := ''
		RETURN
	endif

	c := c + space(4) + 'DEFINE SPLITBOX'
	
	if spb.check_1.value == .t.
		c := c +  ' BOTTOM'
	endif

	if spb.check_2.value == .t.
		c := c + ' HORIZONTAL'
	endif

	c := c + CRLF

	for i := 1 to spb.list_1.itemcount

		n := ALLTRIM ( HMG_UPPER ( spb.list_1.cell(i,1) ) )

		if ALLTRIM ( HMG_UPPER ( spb.list_1.cell(i,2) ) ) == 'WINDOW'

			c := c + CRLF

			c := c + space (8) + 'LOAD WINDOW ' + spb.list_1.cell(i,1) + CRLF

		elseif ALLTRIM ( HMG_UPPER ( spb.list_1.cell(i,2) ) ) == 'BROWSE'

			c := c + CRLF

			c := c + space (8) + 'DEFINE BROWSE ' + spb.list_1.cell(i,1) + CRLF

			* Browse Properties

			c := c + space (12) + 'ALLOWAPPEND ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'AllowAppend'  )  + CRLF

			c := c + space (12) + 'ALLOWDELETE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'AllowDelete'  )  + CRLF

			c := c + space (12) + 'ALLOWEDIT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'AllowEdit'  )  + CRLF

			c := c + space (12) + 'BACKCOLOR ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'BackColor' )  + CRLF

			c := c + space (12) + 'BREAK ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' )  + CRLF

			c := c + space (12) + 'COL ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col'  )  + CRLF

			c := c + space (12) + 'DYNAMICBACKCOLOR ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'DynamicBackColor' )  + CRLF

			c := c + space (12) + 'DYNAMICFORECOLOR ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'DynamicForeColor' )  + CRLF

			c := c + space (12) + 'FIELDS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Fields' )  + CRLF

			c := c + space (12) + 'FONTBOLD ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' )  + CRLF

			c := c + space (12) + 'FONTCOLOR ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontColor' )  + CRLF

			c := c + space (12) + 'FONTITALIC ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' )  + CRLF

			c := c + space (12) + 'FONTNAME "' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName'  ) + '"' + CRLF

			c := c + space (12) + 'FONTUNDERLINE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' )  + CRLF

			c := c + space (12) + 'FONTSIZE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize'  )  + CRLF

			c := c + space (12) + 'FONTSTRIKEOUT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' )  + CRLF

			c := c + space (12) + 'FORMAT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Format' )  + CRLF

			c := c + space (12) + 'HEADERS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Headers' )  + CRLF

			c := c + space (12) + 'HEIGHT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height'  )  + CRLF

			c := c + space (12) + 'HELPID ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId'  )  + CRLF

			c := c + space (12) + 'IMAGE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Image'  )  + CRLF

			c := c + space (12) + 'INPUTMASK ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'InputMask' )  + CRLF

			c := c + space (12) + 'JUSTIFY ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Justify' )  + CRLF

			IF HMG_UPPER ( ALLTRIM ( __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Lines' ) ) ) == '.T.'
				c := c + space (12) + 'NOLINES .F.'   + CRLF
			ELSE
				c := c + space (12) + 'NOLINES .T.' + CRLF
			ENDIF

			c := c + space (12) + 'LOCK ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Lock' )  + CRLF

			c := c + space (12) + 'READONLYFIELDS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ReadOnlyFields' )  + CRLF

			c := c + space (12) + 'ROW ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' )  + CRLF

			c := c + space (12) + 'VALID ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Valid' )  + CRLF

			c := c + space (12) + 'VALIDMESSAGES ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ValidMessages' )  + CRLF

			c := c + space (12) + 'VALUE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' )  + CRLF

			c := c + space (12) + 'VSCROLLBAR ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'vScrollBar' )  + CRLF

			c := c + space (12) + 'TOOLTIP "' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' ) + '"' + CRLF

			c := c + space (12) + 'WHEN ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'When' )  + CRLF

			c := c + space (12) + 'WIDTH ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' )  + CRLF

			c := c + space (12) + 'WIDTHS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Widths'  )  + CRLF

			c := c + space (12) + 'WORKAREA ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'WorkArea' )  + CRLF

			* Browse Events

			c := c + space (12) + 'ONCHANGE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' )  + CRLF

			c := c + space (12) + 'ONDBLCLICK ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnDblClick' )  + CRLF

			c := c + space (12) + 'ONGOTFOCUS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus'  )  + CRLF

			c := c + space (12) + 'ONHEADCLICK ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnHeadClick' )  + CRLF

			c := c + space (12) + 'ONLOSTFOCUS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' )  + CRLF


			c := c + space (8) + 'END BROWSE' + CRLF

		elseif ALLTRIM ( HMG_UPPER ( spb.list_1.cell(i,2) ) ) == 'COMBOBOX'

			c := c + CRLF

			c := c + space (8) + 'DEFINE COMBOBOX ' + spb.list_1.cell(i,1) + CRLF

			* ComboBox Properties

			c := c + space (12) + 'BREAK ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' )  + CRLF

			c := c + space (12) + 'COL ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col'  )  + CRLF

			c := c + space (12) + 'DISPLAYEDIT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'DisplayEdit' )  + CRLF

			c := c + space (12) + 'FONTBOLD ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' )  + CRLF

			c := c + space (12) + 'FONTITALIC ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' )  + CRLF

			c := c + space (12) + 'FONTNAME ' + '"' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName' ) + '"' + CRLF

			c := c + space (12) + 'FONTUNDERLINE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' )  + CRLF

			c := c + space (12) + 'FONTSIZE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' )  + CRLF

			c := c + space (12) + 'FONTSTRIKEOUT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' )  + CRLF

			c := c + space (12) + 'HEIGHT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' )  + CRLF

			c := c + space (12) + 'HELPID ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' )  + CRLF

			c := c + space (12) + 'ITEMS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Items' )  + CRLF

			IF HMG_UPPER ( ALLTRIM ( __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ItemSource' ) ) ) <> 'NIL'
				c := c + space (12) + 'ITEMSOURCE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ItemSource' )  + CRLF
			ENDIF

			c := c + space (12) + 'ROW ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' )  + CRLF

			c := c + space (12) + 'SORT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Sort' )  + CRLF

			c := c + space (12) + 'TABSTOP ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'TabStop' )  + CRLF

			c := c + space (12) + 'TOOLTIP ' + '"' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' ) + '"'  + CRLF

			c := c + space (12) + 'VALUE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' )  + CRLF

			IF ! EMPTY ( __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ValueSource' ) )
				c := c + space (12) + 'VALUESOURCE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ValueSource' )  + CRLF
			ENDIF

			c := c + space (12) + 'VISIBLE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Visible' )  + CRLF

			c := c + space (12) + 'WIDTH ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' )  + CRLF

			* ComboBox Events

			c := c + space (12) + 'ONCHANGE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' )  + CRLF

			c := c + space (12) + 'ONDISPLAYCHANGE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnDisplayChange' )  + CRLF

			c := c + space (12) + 'ONENTER ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnEnter' )  + CRLF

			c := c + space (12) + 'ONGOTFOCUS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' )  + CRLF

			c := c + space (12) + 'ONLOSTFOCUS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' )  + CRLF


			c := c + space (8) + 'END COMBOBOX' + CRLF

		elseif ALLTRIM ( HMG_UPPER ( spb.list_1.cell(i,2) ) ) == 'EDITBOX'

			c := c + CRLF

			c := c + space (8) + 'DEFINE EDITBOX ' + spb.list_1.cell(i,1) + CRLF

			* EditBox Properties

			c := c + space (12) + 'BACKCOLOR ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'BackColor' )  + CRLF

			c := c + space (12) + 'BREAK ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' )  + CRLF

			c := c + space (12) + 'COL ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' )  + CRLF

			IF ALLTRIM ( HMG_UPPER ( __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Field' ) ) ) <> 'NIL'
				c := c + space (12) + 'FIELD ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Field' )  + CRLF
			ENDIF

			c := c + space (12) + 'FONTBOLD ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' )  + CRLF

			c := c + space (12) + 'FONTCOLOR ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontColor' )  + CRLF

			c := c + space (12) + 'FONTITALIC ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' )  + CRLF

			c := c + space (12) + 'FONTNAME ' + '"' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName' ) + '"'  + CRLF

			c := c + space (12) + 'FONTUNDERLINE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' )  + CRLF

			c := c + space (12) + 'FONTSIZE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' )  + CRLF

			c := c + space (12) + 'FONTSTRIKEOUT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' )  + CRLF

			c := c + space (12) + 'HEIGHT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' )  + CRLF

			c := c + space (12) + 'HELPID ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' )  + CRLF

			c := c + space (12) + 'HSCROLLBAR ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'hScrollBar' )  + CRLF

			c := c + space (12) + 'MAXLENGTH ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'MaxLength' )  + CRLF

			c := c + space (12) + 'READONLY ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ReadOnly' )  + CRLF

			c := c + space (12) + 'ROW ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' )  + CRLF

			c := c + space (12) + 'TABSTOP ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'TabStop' )  + CRLF

			c := c + space (12) + 'TOOLTIP ' + '"' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' ) + '"' + CRLF

			c := c + space (12) + 'VALUE ' + '"' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' ) + '"' + CRLF

			c := c + space (12) + 'VISIBLE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Visible' )  + CRLF

			c := c + space (12) + 'VSCROLLBAR ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'vScrollBar' )  + CRLF

			c := c + space (12) + 'WIDTH ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' )  + CRLF

			* EditBox Events

			c := c + space (12) + 'ONCHANGE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' )  + CRLF

			c := c + space (12) + 'ONGOTFOCUS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' )  + CRLF

			c := c + space (12) + 'ONLOSTFOCUS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' )  + CRLF

			c := c + space (8) + 'END EDITBOX' + CRLF

		elseif ALLTRIM ( HMG_UPPER ( spb.list_1.cell(i,2) ) ) == 'GRID'

			c := c + CRLF

			c := c + space (8) + 'DEFINE GRID ' + spb.list_1.cell(i,1) + CRLF

			* Grid Properties

			c := c + space (12) + 'ALLOWEDIT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'AllowEdit' )  + CRLF

			c := c + space (12) + 'BACKCOLOR ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'BackColor' )  + CRLF

			c := c + space (12) + 'BREAK ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' )  + CRLF

			c := c + space (12) + 'COL ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' )  + CRLF

			c := c + space (12) + 'COLUMNCONTROLS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ColumnControls' )  + CRLF

			c := c + space (12) + 'COLUMNVALID ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ColumnValid' )  + CRLF

			c := c + space (12) + 'COLUMNWHEN ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ColumnWhen' )  + CRLF

			c := c + space (12) + 'DYNAMICBACKCOLOR ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'DynamicBackColor' )  + CRLF

			c := c + space (12) + 'DYNAMICFORECOLOR ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'DynamicForeColor' )  + CRLF

			c := c + space (12) + 'FONTBOLD ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' )  + CRLF

			c := c + space (12) + 'FONTCOLOR ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontColor' )  + CRLF

			c := c + space (12) + 'FONTITALIC ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' )  + CRLF

			c := c + space (12) + 'FONTNAME ' + '"' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName' ) + '"'  + CRLF

			c := c + space (12) + 'FONTUNDERLINE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' )  + CRLF

			c := c + space (12) + 'FONTSIZE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' )  + CRLF

			c := c + space (12) + 'FONTSTRIKEOUT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' )  + CRLF

			c := c + space (12) + 'HEADERS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Headers' )  + CRLF

			c := c + space (12) + 'HEIGHT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' )  + CRLF

			c := c + space (12) + 'HELPID ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' )  + CRLF

			c := c + space (12) + 'IMAGE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Image' )  + CRLF

			c := c + space (12) + 'ITEMCOUNT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ItemCount' )  + CRLF

			c := c + space (12) + 'ITEMS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Items' )  + CRLF

			c := c + space (12) + 'JUSTIFY ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Justify' )  + CRLF

			IF HMG_UPPER ( ALLTRIM ( __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Lines' ) ) ) == '.T.'
				c := c + space (12) + 'NOLINES .F.'   + CRLF
			ELSE
				c := c + space (12) + 'NOLINES .T.' + CRLF
			ENDIF

			c := c + space (12) + 'MULTISELECT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'MultiSelect' )  + CRLF

			c := c + space (12) + 'ROW ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' )  + CRLF

			c := c + space (12) + 'SHOWHEADERS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ShowHeaders' )  + CRLF

			c := c + space (12) + 'TOOLTIP ' + '"' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' ) + '"' + CRLF

			c := c + space (12) + 'VALUE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' )  + CRLF

			c := c + space (12) + 'VIRTUAL ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Virtual' )  + CRLF

			c := c + space (12) + 'WIDTH ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' )  + CRLF

			c := c + space (12) + 'WIDTHS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Widths' )  + CRLF

			* Grid Events

			c := c + space (12) + 'ONCHANGE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' )  + CRLF

			c := c + space (12) + 'ONDBLCLICK ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnDblClick' )  + CRLF

			c := c + space (12) + 'ONGOTFOCUS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' )  + CRLF

			c := c + space (12) + 'ONHEADCLICK ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnHeadClick' )  + CRLF

			c := c + space (12) + 'ONLOSTFOCUS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' )  + CRLF

			c := c + space (12) + 'ONQUERYDATA ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnQueryData' )  + CRLF

			c := c + space (8) + 'END GRID' + CRLF

		elseif ALLTRIM ( HMG_UPPER ( spb.list_1.cell(i,2) ) ) == 'LISTBOX'

			c := c + CRLF

			c := c + space (8) + 'DEFINE LISTBOX ' + spb.list_1.cell(i,1) + CRLF

			* ListBox Properties

			c := c + space (12) + 'BACKCOLOR ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'BackColor' )  + CRLF

			c := c + space (12) + 'BREAK ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' )  + CRLF

			c := c + space (12) + 'COL ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' )  + CRLF

			c := c + space (12) + 'FONTBOLD ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' )  + CRLF

			c := c + space (12) + 'FONTCOLOR ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontColor' )  + CRLF

			c := c + space (12) + 'FONTITALIC ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' )  + CRLF

			c := c + space (12) + 'FONTNAME ' + '"' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName' ) + '"'  + CRLF

			c := c + space (12) + 'FONTUNDERLINE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' )  + CRLF

			c := c + space (12) + 'FONTSIZE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' )  + CRLF

			c := c + space (12) + 'FONTSTRIKEOUT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' )  + CRLF

			c := c + space (12) + 'HEIGHT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' )  + CRLF

			c := c + space (12) + 'HELPID ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' )  + CRLF

			c := c + space (12) + 'ITEMS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Items' )  + CRLF

			c := c + space (12) + 'MULTISELECT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'MultiSelect' )  + CRLF

			c := c + space (12) + 'ROW ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' )  + CRLF

			c := c + space (12) + 'SORT ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Sort' )  + CRLF

			c := c + space (12) + 'TABSTOP ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'TabStop' )  + CRLF

			c := c + space (12) + 'TOOLTIP ' + '"' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' ) + '"' + CRLF

			c := c + space (12) + 'VALUE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' )  + CRLF

			c := c + space (12) + 'VISIBLE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Visible' )  + CRLF

			c := c + space (12) + 'WIDTH ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' )  + CRLF

			* ListBox Events

			c := c + space (12) + 'ONCHANGE ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' )  + CRLF

			c := c + space (12) + 'ONDBLCLICK ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnDblClick' )  + CRLF

			c := c + space (12) + 'ONGOTFOCUS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' )  + CRLF

			c := c + space (12) + 'ONLOSTFOCUS ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' )  + CRLF

			c := c + space (8) + 'END LISTBOX' + CRLF

		elseif ALLTRIM ( HMG_UPPER ( spb.list_1.cell(i,2) ) ) == 'RICHEDITBOX'

			c := c + CRLF

			c := c + space (8) + 'DEFINE RICHEDITBOX ' + spb.list_1.cell(i,1) + CRLF

			* RichEditBox Properties

			c := c + space (12) + 'BACKCOLOR ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'BackColor' )  + CRLF

			c := c + space (12) + 'BREAK ' + __MVGET ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' )  + CRLF

			c := c + space (12) + 'COL ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' )  + CRLF

			IF HMG_UPPER ( ALLTRIM ( __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Field' ) ) ) <> 'NIL'
				c := c + space (12) + 'FIELD ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Field' )  + CRLF
			ENDIF

			c := c + space (12) + 'FONTBOLD ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' )  + CRLF

			c := c + space (12) + 'FONTITALIC ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' )  + CRLF

			c := c + space (12) + 'FONTNAME ' + '"' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Fontname' ) + '"' + CRLF

			c := c + space (12) + 'FONTUNDERLINE ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' )  + CRLF

			c := c + space (12) + 'FONTSIZE ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' )  + CRLF

			c := c + space (12) + 'FONTSTRIKEOUT ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' )  + CRLF

			c := c + space (12) + 'HEIGHT ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' )  + CRLF

			c := c + space (12) + 'HELPID ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' )  + CRLF

			c := c + space (12) + 'MAXLENGTH ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'MaxLength' )  + CRLF

			c := c + space (12) + 'READONLY ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ReadOnly' )  + CRLF

			c := c + space (12) + 'ROW ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' )  + CRLF

			c := c + space (12) + 'TABSTOP ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'TabStop' )  + CRLF

			c := c + space (12) + 'TOOLTIP ' + '"' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' ) + '"' + CRLF

			c := c + space (12) + 'VALUE ' + '"' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' ) + '"' + CRLF

			c := c + space (12) + 'VISIBLE ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Visible' )  + CRLF

			c := c + space (12) + 'WIDTH ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' )  + CRLF

			* RichEditBox Events

			c := c + space (12) + 'ONCHANGE ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' )  + CRLF

			c := c + space (12) + 'ONGOTFOCUS ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' )  + CRLF

			c := c + space (12) + 'ONLOSTFOCUS ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' )  + CRLF

			c := c + space (8) + 'END RICHEDITBOX' + CRLF

		elseif ALLTRIM ( HMG_UPPER ( spb.list_1.cell(i,2) ) ) == 'TOOLBAR'

			c := c + CRLF

			c := c + __MVGET ( ALLTRIM(n) + 'SpxToolBar' ) 

		elseif ALLTRIM ( HMG_UPPER ( spb.list_1.cell(i,2) ) ) == 'TREE'

			c := c + CRLF

			c := c + space (8) + 'DEFINE TREE ' + ALLTRIM ( n ) + ' AT ' +  __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Row' ) + ' , ' +  __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Col' ) + ' WIDTH ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Width' ) + ' HEIGHT ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Height' ) + ' VALUE ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Value' )  + ' FONT ' + chr(34) + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontName' ) + chr(34) + ' SIZE ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontSize' )  + IF ( __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontBold' ) =='.T.',' BOLD','') + IF ( __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontItalic' ) =='.T.',' ITALIC','') + IF ( __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontUnderLine' ) =='.T.',' UNDERLINE','') + IF ( __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'FontStrikeOut' ) =='.T.',' STRIKEOUT','') + ' TOOLTIP ' + chr(34) + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ToolTip' ) + chr(34)  + ' ON GOTFOCUS ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnGotFocus' )  + ' ON CHANGE ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnChange' ) + ' ON LOSTFOCUS ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnLostFocus' ) + ' ON DBLCLICK ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'OnDblClick' ) + ' NODEIMAGES ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'NodeImages' ) + ' ITEMIMAGES ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ItemImages' ) + if ( __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'RootButton' ) == '.T.' , '' , ' NOROOTBUTTON' ) + if ( __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'ItemIds' ) == '.T.' , ' ITEMIDS' , '' ) + ' HELPID ' + __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'HelpId' ) + IF ( __MVGET  ( HMG_UPPER ( ALLTRIM ( n ) ) + 'Break' ) =='.T.',' BREAK','') + CRLF

			c := c + space (8) + 'END TREE' + CRLF

		endif

	next i

	c := c + CRLF

	c := c + space(4) + 'END SPLITBOX' + CRLF

	_hmgide_CurrentSplitBox := c 

	DesignFormModified := .T.

RETURN

PROCEDURE sp4
local ant
local cur
local i

	i := spb.list_1.value

	if i == 0
		msgstop( aMsgs [ 193 ] ,'HMG IDE')
		RETURN
	endif

	if i == 1 
		RETURN
	endif

	ant := spb.list_1.item(i-1)
	cur := spb.list_1.item(i)

	spb.list_1.item(i-1) := cur
	spb.list_1.item(i) := ant

	spb.list_1.value := i - 1 

RETURN

PROCEDURE sp5
local cur
local pos
local i

	i := spb.list_1.value

	if i == 0
		msgstop( aMsgs [ 193 ] ,'HMG IDE')
		RETURN
	endif

	if i == spb.list_1.itemcount 
		RETURN
	endif

	pos := spb.list_1.item(i+1)
	cur := spb.list_1.item(i)

	spb.list_1.item(i+1) := cur
	spb.list_1.item(i) := pos

	spb.list_1.value := i + 1 

RETURN