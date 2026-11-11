*------------------------------------------------------------------------------*
PROCEDURE SaveProject
*------------------------------------------------------------------------------*
Local Project
Local i
Local Item

      If Empty(ProjectName)
         RETURN
      EndIf

	Project := ''

	For i := 1 To Project.List_1.ItemCount

		Item := Project.List_1.Item ( i )

		if HB_URIGHT ( Item , 7 ) == ' (Main)'
			Item := HB_ULEFT ( Item , HMG_LEN (Item) - 7 )
			Item := ALLTRIM(Item)
		endif

		Project := Project + Item + CRLF

	Next i


	SaveString ( ProjectName , Project )

	SaveResources()

RETURN