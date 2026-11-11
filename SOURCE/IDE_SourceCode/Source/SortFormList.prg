PROCEDURE SortFormList (value)
Local i , j 
Local aux
Local last

	last := Project.List_2.Item ( Project.List_2.ItemCount )

	For i := 1 To Project.List_2.ItemCount - 1

		For j := i+1 To Project.List_2.ItemCount

			if HMG_UPPER(Project.List_2.Item ( i ) ) > HMG_UPPER ( Project.List_2.Item ( j ) )

				aux := Project.List_2.Item ( i )
				Project.List_2.Item ( i ) := Project.List_2.Item ( j )
				Project.List_2.Item ( j ) := aux

			EndIf

		Next j

	Next i

	if VALTYPE ( value ) = 'N'
		Project.List_2.Value := value
	else

		For i := 1 to Project.List_2.ItemCount

			if 	ALLTRIM ( HMG_UPPER(Project.List_2.Item ( i ) ) ) ;
				== ;
				ALLTRIM ( HMG_UPPER( Last ) ) 

				Project.List_2.Value := i
				Exit

			endif

		Next i

	endif

RETURN