*------------------------------------------------------------------------------*
PROCEDURE UpdateControlProperties (i)
*------------------------------------------------------------------------------*
Local Row 
Local Col 
Local Width 
Local Height 
Local Name
Local Type
Local z
Local aProperties
Local aEvents	
Local x

	Row	:= _HMG_SYSDATA [ 18 ] [i]
	Col	:= _HMG_SYSDATA [ 19 ] [i]
	Width	:= _HMG_SYSDATA [ 20 ] [i]
	Height	:= _HMG_SYSDATA [ 21 ] [i]
	Name	:= _HMG_SYSDATA [  2 ] [i]

	if _HMG_SYSDATA [ 23 ] [i] != -1 .and. _HMG_SYSDATA [ 24 ] [i] != -1
		Row := Row - _HMG_SYSDATA [ 23 ] [i]
		Col := Col - _HMG_SYSDATA [ 24 ] [i]
	endif

	If	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] > 10
		***************************************************************
		Type := 'USER'
		***************************************************************

		z := _HMG_SYSDATA [ 39 ] [ i ] - 10

		aProperties	:= aClone ( aComponentProperties [z] )
		aEvents		:= aClone ( aComponentEvents	 [z] )

		aSort ( aProperties )
		aSort ( aEvents )

		Properties.Grid_1.DeleteAllItems

		For x := 1 To HMG_LEN ( aProperties )

			If HMG_UPPER( ALLTRIM( aProperties[x] ) ) == 'NAME'

				Properties.Grid_1.AddItem ( {'Name',Name } )

			ElseIf HMG_UPPER( ALLTRIM( aProperties[x] ) ) == 'COL'

				Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )

			ElseIf HMG_UPPER( ALLTRIM( aProperties[x] ) ) == 'ROW'

				Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )

			ElseIf HMG_UPPER( ALLTRIM( aProperties[x] ) ) == 'WIDTH'

				Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

			ElseIf HMG_UPPER( ALLTRIM( aProperties[x] ) ) == 'HEIGHT'			

				Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )

			Else

				Properties.Grid_1.AddItem ( { aProperties[x] , __MVGET ( Name + aProperties [x] ) } )

			EndIf

		Next x

		Properties.Grid_2.DeleteAllItems

		For x := 1 To HMG_LEN ( aEvents )

			Properties.Grid_2.AddItem ( { aEvents [x] , __MVGET ( Name + aEvents [x] )  , '+' , '-' , '...'} )

		Next x


	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'BUTTON' .and. _HMG_SYSDATA [ 39 ] [ i ] == 0
		***************************************************************
		Type := 'BUTTON'
		***************************************************************

		Properties.Grid_1.DeleteAllItems

		Properties.Grid_1.AddItem ( {'Caption', __MVGET ( Name + 'Caption' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'Flat', __MVGET ( Name + 'Flat' ) } )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'MultiLine', __MVGET ( Name + 'MultiLine' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'PictAlignment', __MVGET ( Name + 'PictAlignment' ) } )
		Properties.Grid_1.AddItem ( {'Picture', __MVGET ( Name + 'Picture' ) } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'TabStop', __MVGET ( Name + 'TabStop' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Transparent', __MVGET ( Name + 'Transparent' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'Action', __MVGET ( Name + 'Action' ) , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( Name + 'OnGotFocus' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( Name + 'OnLostFocus' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'CHECKBOX' .and. _HMG_SYSDATA [ 39 ] [ i ] == 0
		***************************************************************
		Type := 'CHECKBOX'
		***************************************************************
		Properties.Grid_1.DeleteAllItems

		Properties.Grid_1.AddItem ( {'BackColor', __MVGET ( Name + 'BackColor' ) } )
		Properties.Grid_1.AddItem ( {'Caption', __MVGET ( Name + 'Caption' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'Field', __MVGET ( Name + 'Field' ) } )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontColor', __MVGET ( Name + 'FontColor' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'TabStop', __MVGET ( Name + 'TabStop' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Transparent', __MVGET ( Name + 'Transparent' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'OnChange', __MVGET ( Name + 'OnChange' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( Name + 'OnGotFocus' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( Name + 'OnLostFocus' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LIST'
		***************************************************************
		Type := 'LISTBOX'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'BackColor', __MVGET ( Name + 'BackColor' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'DragItems', __MVGET ( Name + 'DragItems' ) } )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontColor', __MVGET ( Name + 'FontColor' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Items',  __MVGET ( Name + 'Items' ) } )
		Properties.Grid_1.AddItem ( {'MultiSelect',  __MVGET ( Name + 'MultiSelect' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'Sort', __MVGET ( Name + 'Sort' ) } )
		Properties.Grid_1.AddItem ( {'TabStop', __MVGET ( Name + 'TabStop' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'OnChange', __MVGET ( Name + 'OnChange' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnDblClick', __MVGET ( Name + 'OnDblClick' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( Name + 'OnGotFocus' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( Name + 'OnLostFocus'  ) , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'COMBO'
		***************************************************************
		Type := 'COMBOBOX'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'DisplayEdit', __MVGET ( Name + 'DisplayEdit' ) } )
		Properties.Grid_1.AddItem ( {'DroppedWidth', __MVGET ( Name + 'DroppedWidth' ) } )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Image',  __MVGET ( Name + 'Image' ) } )
		Properties.Grid_1.AddItem ( {'Items',  __MVGET ( Name + 'Items' ) } )
		Properties.Grid_1.AddItem ( {'ItemSource',  __MVGET ( Name + 'ItemSource' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'Sort', __MVGET ( Name + 'Sort' ) } )
		Properties.Grid_1.AddItem ( {'TabStop', __MVGET ( Name + 'TabStop' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'ValueSource',  __MVGET ( Name + 'ValueSource' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'OnChange', __MVGET ( Name + 'OnChange' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnCloseUp', __MVGET ( Name + 'OnCloseUp' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnDisplayChange', __MVGET ( Name + 'OnDisplayChange' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnDropDown', __MVGET ( Name + 'OnDropDown' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnEnter', __MVGET ( Name + 'OnEnter' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( Name + 'OnGotFocus' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( Name + 'OnLostFocus' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'CHECKBOX' .and. _HMG_SYSDATA [ 39 ] [ i ] == 1
		***************************************************************
		Type := 'CHECKBUTTON'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'Caption', __MVGET ( Name + 'Caption' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'Picture', __MVGET ( Name + 'Picture' ) } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'TabStop', __MVGET ( Name + 'TabStop' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'OnChange', __MVGET ( Name + 'OnChange' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( Name + 'OnGotFocus' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( Name + 'OnLostFocus' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'GRID'
		***************************************************************
		Type := 'GRID'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'AllowAppend', __MVGET ( Name + 'AllowAppend' ) } )
		Properties.Grid_1.AddItem ( {'AllowDelete', __MVGET ( Name + 'AllowDelete' ) } )
		Properties.Grid_1.AddItem ( {'AllowEdit', __MVGET ( Name + 'AllowEdit' ) } )
		Properties.Grid_1.AddItem ( {'BackColor', __MVGET ( Name + 'BackColor' ) } )
		Properties.Grid_1.AddItem ( {'Buffered', __MVGET ( Name + 'Buffered' ) } )
		Properties.Grid_1.AddItem ( {'CellNavigation', __MVGET ( Name + 'CellNavigation' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'ColumnControls', __MVGET ( Name + 'ColumnControls' ) } )
		Properties.Grid_1.AddItem ( {'ColumnFields', __MVGET ( Name + 'ColumnFields' ) } )
		Properties.Grid_1.AddItem ( {'ColumnValid', __MVGET ( Name + 'ColumnValid' ) } )
		Properties.Grid_1.AddItem ( {'ColumnWhen', __MVGET ( Name + 'ColumnWhen' ) } )
		Properties.Grid_1.AddItem ( {'DynamicBackColor', __MVGET ( Name + 'DynamicBackColor' ) } )
		Properties.Grid_1.AddItem ( {'DynamicForeColor', __MVGET ( Name + 'DynamicForeColor' ) } )
		Properties.Grid_1.AddItem ( {'DynamicDisplay', __MVGET ( Name + 'DynamicDisplay' ) } )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontColor', __MVGET ( Name + 'FontColor' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Headers',  __MVGET ( Name + 'Headers' ) } )
		Properties.Grid_1.AddItem ( {'HeaderImages',  __MVGET ( Name + 'HeaderImages' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId',  __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Image',  __MVGET ( Name + 'Image' ) } )
		Properties.Grid_1.AddItem ( {'ItemCount',  __MVGET ( Name + 'ItemCount' ) } )
		Properties.Grid_1.AddItem ( {'Items',  __MVGET ( Name + 'Items' ) } )
		Properties.Grid_1.AddItem ( {'Justify',  __MVGET ( Name + 'Justify' ) } )
		Properties.Grid_1.AddItem ( {'Lines', __MVGET ( Name + 'Lines' ) } )
		Properties.Grid_1.AddItem ( {'LockColumns', __MVGET ( Name + 'LockColumns' ) } )
		Properties.Grid_1.AddItem ( {'MultiSelect',  __MVGET ( Name + 'MultiSelect' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'RowSource', __MVGET ( Name + 'RowSource' ) } )
		Properties.Grid_1.AddItem ( {'ShowHeaders', __MVGET ( Name + 'ShowHeaders' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Virtual',  __MVGET ( Name + 'Virtual' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )
		Properties.Grid_1.AddItem ( {'Widths',  __MVGET ( Name + 'Widths' ) } )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'OnChange', __MVGET ( Name + 'OnChange' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnDblClick', __MVGET ( Name + 'OnDblClick' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( Name + 'OnGotFocus' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnHeadClick', __MVGET ( Name + 'OnHeadClick' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( Name + 'OnLostFocus' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnQueryData', __MVGET ( Name + 'OnQueryData' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnSave', __MVGET ( Name + 'OnSave' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'SLIDER'
		***************************************************************
		Type := 'SLIDER'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'BackColor', __MVGET ( Name + 'BackColor' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'Orientation',  __MVGET ( Name + 'Orientation' ) } )
		Properties.Grid_1.AddItem ( {'RangeMax',  __MVGET ( Name + 'RangeMax' ) } )
		Properties.Grid_1.AddItem ( {'RangeMin',  __MVGET ( Name + 'RangeMin' ) } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'TabStop', __MVGET ( Name + 'TabStop' ) } )
		Properties.Grid_1.AddItem ( {'TickMarks', __MVGET ( Name + 'TickMarks' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'OnChange', __MVGET ( Name + 'OnChange' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'SPINNER'
		***************************************************************
		Type := 'SPINNER'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'BackColor', __MVGET ( Name + 'BackColor' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontColor', __MVGET ( Name + 'FontColor' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Increment', __MVGET ( Name + 'Increment' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'RangeMax',  __MVGET ( Name + 'RangeMax' ) } )
		Properties.Grid_1.AddItem ( {'RangeMin',  __MVGET ( Name + 'RangeMin' ) } )
		Properties.Grid_1.AddItem ( {'ReadOnly',  __MVGET ( Name + 'ReadOnly' ) } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'TabStop', __MVGET ( Name + 'TabStop' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )
		Properties.Grid_1.AddItem ( {'Wrap',  __MVGET ( Name + 'Wrap' ) } )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'OnChange', __MVGET ( Name + 'OnChange' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( Name + 'OnGotFocus' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( Name + 'OnLostFocus' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'IMAGE'
		***************************************************************
		Type := 'IMAGE'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'Picture',  __MVGET ( Name + 'Picture' ) } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'Stretch', __MVGET ( Name + 'Stretch' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'Action', __MVGET ( Name + 'Action' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'TREE'
		***************************************************************
		Type := 'TREE'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'ItemIds', __MVGET ( Name + 'ItemIds' ) } )
		Properties.Grid_1.AddItem ( {'ItemImages', __MVGET ( Name + 'ItemImages' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'NodeImages', __MVGET ( Name + 'NodeImages' ) } )
		Properties.Grid_1.AddItem ( {'RootButton', __MVGET ( Name + 'RootButton' ) } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'OnChange', __MVGET ( Name + 'OnChange' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnDblClick', __MVGET ( Name + 'OnDblClick' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( Name + 'OnGotFocus' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( Name + 'OnLostFocus' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'DATEPICK'
		***************************************************************
		Type := 'DATEPICKER'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'Field', __MVGET ( Name + 'Field' ) } )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'RightAlign', __MVGET ( Name + 'RightAlign' ) } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'ShowNone', __MVGET ( Name + 'ShowNone' ) } )
		Properties.Grid_1.AddItem ( {'TabStop', __MVGET ( Name + 'TabStop' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'UpDown', __MVGET ( Name + 'UpDown' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'OnChange', __MVGET ( Name + 'OnChange' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnEnter', __MVGET ( Name + 'OnEnter' ) , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( Name + 'OnGotFocus' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( Name + 'OnLostFocus' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'TEXT'
		***************************************************************
		Type := 'TEXTBOX'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'BackColor', __MVGET ( Name + 'BackColor' ) } )
		Properties.Grid_1.AddItem ( {'CaseConvert', __MVGET ( Name + 'CaseConvert' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'DataType', __MVGET ( Name + 'DataType' ) } )
		Properties.Grid_1.AddItem ( {'DisabledBackColor', __MVGET ( Name + 'DisabledBackColor' ) } )
		Properties.Grid_1.AddItem ( {'DisabledFontColor', __MVGET ( Name + 'DisabledFontColor' ) } )
		Properties.Grid_1.AddItem ( {'Field', __MVGET ( Name + 'Field' ) } )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontColor', __MVGET ( Name + 'FontColor' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Format', __MVGET ( Name + 'Format' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'InputMask', __MVGET ( Name + 'InputMask' ) } )
		Properties.Grid_1.AddItem ( {'MaxLength', __MVGET ( Name + 'MaxLength' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'Password',  __MVGET ( Name + 'Password' ) } )
		Properties.Grid_1.AddItem ( {'ReadOnly',  __MVGET ( Name + 'ReadOnly' ) } )
		Properties.Grid_1.AddItem ( {'RightAlign', __MVGET ( Name + 'RightAlign' ) } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'TabStop', __MVGET ( Name + 'TabStop' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'OnChange', __MVGET ( Name + 'OnChange' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnEnter', __MVGET ( Name + 'OnEnter' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( Name + 'OnGotFocus' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( Name + 'OnLostFocus' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'EDIT'
		***************************************************************
		Type := 'EDITBOX'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'BackColor', __MVGET ( Name + 'BackColor' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'DisabledBackColor', __MVGET ( Name + 'DisabledBackColor' ) } )
		Properties.Grid_1.AddItem ( {'DisabledFontColor', __MVGET ( Name + 'DisabledFontColor' ) } )
		Properties.Grid_1.AddItem ( {'Field', __MVGET ( Name + 'Field' ) } )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontColor', __MVGET ( Name + 'FontColor' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'HScrollBar', __MVGET ( Name + 'hScrollBar' ) } )
		Properties.Grid_1.AddItem ( {'MaxLength', __MVGET ( Name + 'MaxLength' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'ReadOnly',  __MVGET ( Name + 'ReadOnly' ) } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'TabStop', __MVGET ( Name + 'TabStop' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'VScrollBar', __MVGET ( Name + 'VScrollBar' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'OnChange', __MVGET ( Name + 'OnChange' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( Name + 'OnGotFocus' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( Name + 'OnLostFocus' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 0
		***************************************************************
		Type := 'LABEL'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'Alignment', __MVGET ( Name + 'Alignment' ) } )
		Properties.Grid_1.AddItem ( {'AutoSize', __MVGET ( Name + 'AutoSize' ) } )
		Properties.Grid_1.AddItem ( {'BackColor', __MVGET ( Name + 'BackColor' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontColor', __MVGET ( Name + 'FontColor' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Transparent', __MVGET ( Name + 'Transparent' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'Action', __MVGET ( Name + 'Action' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'BROWSE'
		***************************************************************
		Type := 'BROWSE'
		***************************************************************
		Properties.Grid_1.DeleteAllItems

		Properties.Grid_1.AddItem ( {'AllowAppend', __MVGET ( Name + 'AllowAppend' ) } )
		Properties.Grid_1.AddItem ( {'AllowDelete', __MVGET ( Name + 'AllowDelete' ) } )
		Properties.Grid_1.AddItem ( {'AllowEdit', __MVGET ( Name + 'AllowEdit' ) } )
		Properties.Grid_1.AddItem ( {'BackColor', __MVGET ( Name + 'BackColor' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'DisplayItems', __MVGET ( Name + 'DisplayItems' ) } )
		Properties.Grid_1.AddItem ( {'DynamicBackColor', __MVGET ( Name + 'DynamicBackColor' ) } )
		Properties.Grid_1.AddItem ( {'DynamicForeColor', __MVGET ( Name + 'DynamicForeColor' ) } )
		Properties.Grid_1.AddItem ( {'Fields',  __MVGET ( Name + 'Fields' ) } )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontColor', __MVGET ( Name + 'FontColor' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Format', __MVGET ( Name + 'Format' ) } )
		Properties.Grid_1.AddItem ( {'Headers',  __MVGET ( Name + 'Headers' ) } )
		Properties.Grid_1.AddItem ( {'HeaderImages',  __MVGET ( Name + 'HeaderImages' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Image',  __MVGET ( Name + 'Image' ) } )
		Properties.Grid_1.AddItem ( {'InputItems',  __MVGET ( Name + 'InputItems' ) } )
		Properties.Grid_1.AddItem ( {'InputMask',  __MVGET ( Name + 'InputMask' ) } )
		Properties.Grid_1.AddItem ( {'Justify',  __MVGET ( Name + 'Justify' ) } )
		Properties.Grid_1.AddItem ( {'Lines', __MVGET ( Name + 'Lines' ) } )
		Properties.Grid_1.AddItem ( {'Lock', __MVGET ( Name + 'Lock' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'ReadOnlyFields',  __MVGET ( Name + 'ReadOnlyFields' ) } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'Valid', __MVGET ( Name + 'Valid' ) } )
		Properties.Grid_1.AddItem ( {'ValidMessages', __MVGET ( Name + 'ValidMessages' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'vScrollBar',  __MVGET ( Name + 'vScrollBar' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'When', __MVGET ( Name + 'When' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )
		Properties.Grid_1.AddItem ( {'Widths',  __MVGET ( Name + 'Widths' ) } )
		Properties.Grid_1.AddItem ( {'WorkArea',  __MVGET ( Name + 'WorkArea' ) } )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'OnChange', __MVGET ( Name + 'OnChange' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnDblClick', __MVGET ( Name + 'OnDblClick' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( Name + 'OnGotFocus' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnHeadClick', __MVGET ( Name + 'OnHeadClick' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( Name + 'OnLostFocus' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'RADIOGROUP'
		***************************************************************
		Type := 'RADIOGROUP'
		***************************************************************
		Properties.Grid_1.DeleteAllItems

		Properties.Grid_1.AddItem ( {'BackColor', __MVGET ( Name + 'BackColor' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontColor', __MVGET ( Name + 'FontColor' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'Orientation',  __MVGET ( Name + 'Orientation' ) } )
		Properties.Grid_1.AddItem ( {'Options',  __MVGET ( Name + 'Options' ) } )
		Properties.Grid_1.AddItem ( {'ReadOnly',  __MVGET ( Name + 'ReadOnly' ) } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'Spacing', __MVGET ( Name + 'Spacing' ) } )
		Properties.Grid_1.AddItem ( {'TabStop', __MVGET ( Name + 'TabStop' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Transparent', __MVGET ( Name + 'Transparent' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'OnChange', __MVGET ( Name + 'OnChange' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'FRAME'
		***************************************************************
		Type := 'FRAME'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'BackColor', __MVGET ( Name + 'BackColor' ) } )
		Properties.Grid_1.AddItem ( {'Caption', __MVGET ( Name + 'Caption' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontColor', __MVGET ( Name + 'FontColor' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'Transparent', __MVGET ( Name + 'Transparent' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'TAB'
		***************************************************************
		Type := 'TAB'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'Buttons', __MVGET ( Name + 'Buttons' ) } )
		Properties.Grid_1.AddItem ( {'Captions', __MVGET ( Name + 'Captions' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'Flat', __MVGET ( Name + 'Flat' ) } )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HotTrack', __MVGET ( Name + 'HotTrack' ) } )
		Properties.Grid_1.AddItem ( {'Multiline', __MVGET ( Name + 'Multiline' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'PageCount', __MVGET ( Name + 'PageCount' ) } )
		Properties.Grid_1.AddItem ( {'PageImages', __MVGET ( Name + 'PageImages' ) } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'TabStop', __MVGET ( Name + 'TabStop' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Vertical',  __MVGET ( Name + 'Vertical' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'OnChange', __MVGET ( Name + 'OnChange' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'ANIMATEBOX'
		***************************************************************
		Type := 'ANIMATEBOX'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'AutoPlay', __MVGET ( Name + 'AutoPlay' ) } )
		Properties.Grid_1.AddItem ( {'Center', __MVGET ( Name + 'Center' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'File', __MVGET ( Name + 'File' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'Transparent', __MVGET ( Name + 'Transparent' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 6
		***************************************************************
		Type := 'HYPERLINK'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'Address', __MVGET ( Name + 'Address' ) } )
		Properties.Grid_1.AddItem ( {'AutoSize', __MVGET ( Name + 'AutoSize' ) } )
		Properties.Grid_1.AddItem ( {'BackColor', __MVGET ( Name + 'BackColor' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontColor', __MVGET ( Name + 'FontColor' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'HandCursor', __MVGET ( Name + 'HandCursor' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Value', __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )

		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'MONTHCAL'
		***************************************************************
		Type := 'MONTHCALENDAR'
		***************************************************************

		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'TabStop', __MVGET ( Name + 'TabStop' ) } )
		Properties.Grid_1.AddItem ( {'Today', __MVGET ( Name + 'Today' ) } )
		Properties.Grid_1.AddItem ( {'TodayCircle', __MVGET ( Name + 'TodayCircle' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'WeekNumbers',  __MVGET ( Name + 'WeekNumbers' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'OnChange', __MVGET ( Name + 'OnChange' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'RICHEDIT'
		***************************************************************
		Type := 'RICHEDITBOX'
		***************************************************************

		Properties.Grid_1.DeleteAllItems

		Properties.Grid_1.AddItem ( {'BackColor', __MVGET ( Name + 'BackColor' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'Field', __MVGET ( Name + 'Field' ) } )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'MaxLength', __MVGET ( Name + 'MaxLength' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'ReadOnly',  __MVGET ( Name + 'ReadOnly' ) } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'TabStop', __MVGET ( Name + 'TabStop' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'OnChange', __MVGET ( Name + 'OnChange' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( Name + 'OnGotFocus' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( Name + 'OnLostFocus' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 2
		***************************************************************
		Type := 'PROGRESSBAR'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'BackColor', __MVGET ( Name + 'BackColor' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'ForeColor', __MVGET ( Name + 'ForeColor' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'Orientation',  __MVGET ( Name + 'Orientation' ) } )
		Properties.Grid_1.AddItem ( {'RangeMax',  __MVGET ( Name + 'RangeMax' ) } )
		Properties.Grid_1.AddItem ( {'RangeMin',  __MVGET ( Name + 'RangeMin' ) } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'Smooth', __MVGET ( Name + 'Smooth' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 3
		***************************************************************
		Type := 'PLAYER'
		***************************************************************
		Properties.Grid_1.DeleteAllItems

		Properties.Grid_1.AddItem ( {'AutoSizeMovie', __MVGET ( Name + 'AutoSizeMovie' ) } )
		Properties.Grid_1.AddItem ( {'AutoSizeWindow', __MVGET ( Name + 'AutoSizeWindow' ) } )
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'ErrorDlg', __MVGET ( Name + 'ErrorDlg' ) } )
		Properties.Grid_1.AddItem ( {'File', __MVGET ( Name + 'File' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Menu', __MVGET ( Name + 'Menu' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'Open', __MVGET ( Name + 'Open' ) } )
		Properties.Grid_1.AddItem ( {'PlayBar', __MVGET ( Name + 'PlayBar' ) } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'ShowAll', __MVGET ( Name + 'ShowAll' ) } )
		Properties.Grid_1.AddItem ( {'ShowMode', __MVGET ( Name + 'ShowMode' ) } )
		Properties.Grid_1.AddItem ( {'ShowName', __MVGET ( Name + 'ShowName' ) } )
		Properties.Grid_1.AddItem ( {'ShowPosition', __MVGET ( Name + 'ShowPosition' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 4
		***************************************************************
		Type := 'IPADDRESS'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'FontBold', __MVGET ( Name + 'FontBold' ) } )
		Properties.Grid_1.AddItem ( {'FontItalic', __MVGET ( Name + 'FontItalic' ) } )
		Properties.Grid_1.AddItem ( {'FontName', __MVGET ( Name + 'FontName' ) } )
		Properties.Grid_1.AddItem ( {'FontUnderLine', __MVGET ( Name + 'FontUnderLine' ) } )
		Properties.Grid_1.AddItem ( {'FontSize', __MVGET ( Name + 'FontSize' ) } )
		Properties.Grid_1.AddItem ( {'FontStrikeOut', __MVGET ( Name + 'FontStrikeOut' ) } )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'HelpId', __MVGET ( Name + 'HelpId' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'TabStop', __MVGET ( Name + 'TabStop' ) } )
		Properties.Grid_1.AddItem ( {'ToolTip', __MVGET ( Name + 'ToolTip' ) } )
		Properties.Grid_1.AddItem ( {'Value',  __MVGET ( Name + 'Value' ) } )
		Properties.Grid_1.AddItem ( {'Visible', __MVGET ( Name + 'Visible' ) } )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'OnChange', __MVGET ( Name + 'OnChange' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnGotFocus', __MVGET ( Name + 'OnGotFocus' )  , '+' , '-' , '...'} )
		Properties.Grid_2.AddItem ( {'OnLostFocus', __MVGET ( Name + 'OnLostFocus' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'BUTTON' .and. _HMG_SYSDATA [ 39 ] [ i ] == 5
		***************************************************************
		Type := 'TIMER'
		***************************************************************
		Properties.Grid_1.DeleteAllItems
		Properties.Grid_1.AddItem ( {'Interval',  __MVGET ( Name + 'Interval' ) } )
		Properties.Grid_1.AddItem ( {'Name',Name } )

		Properties.Grid_2.DeleteAllItems
		Properties.Grid_2.AddItem ( {'Action',  __MVGET ( Name + 'Action' )  , '+' , '-' , '...'} )

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 7
		***************************************************************
		Type := 'ACTIVEX'
		***************************************************************
		Properties.Grid_1.DeleteAllItems

		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'ProgId',  __MVGET ( Name + 'ProgId' ) } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems

	ElseIf	_HMG_SYSDATA [ 1 ] [ i ] == 'LABEL' .and. _HMG_SYSDATA [ 39 ] [ i ] == 8
		***************************************************************
		Type := 'CHILDWINDOW'
		***************************************************************
		Properties.Grid_1.DeleteAllItems

		Properties.Grid_1.AddItem ( {'Col',ALLTRIM(STR(Col))} )
		Properties.Grid_1.AddItem ( {'Height',ALLTRIM(STR(Height))} )
		Properties.Grid_1.AddItem ( {'Name',Name } )
		Properties.Grid_1.AddItem ( {'Row',ALLTRIM(STR(Row))} )
		Properties.Grid_1.AddItem ( {'Width',ALLTRIM(STR(Width))} )

		Properties.Grid_2.DeleteAllItems

	EndIf

	Form_Main.StatusBar.Item (2 + STATUSITEM_OFFSET) := 'r:' + ALLTRIM(STR(Row)) + ' c:' + ALLTRIM(STR(Col)) + ' w:' + ALLTRIM(STR(Width)) + ' h:' + ALLTRIM(STR(Height))

RETURN