// Utilities
// Purpose : Solve different odd situations on an adhoc basis
// 1. Remove purchase blanket order that the user cannot remove because everything has not been received/invoiced

report 50149 RemovePurchBlanketOrderHard
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;
    Permissions = 
        tabledata "Purchase Header" = rimd,
        tabledata "Purchase Line" = rimd;
    
    dataset
    {
        dataitem(PurchaseHeader; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") order(ascending);

            trigger OnPreDataItem()
            var
                myInt: Integer;
            begin
                PurchaseHeader.Reset();
                PurchaseHeader.SetRange("Document Type",pDocType);
                PurchaseHeader.setrange("No.",pDocNo);
            end;

        trigger OnAfterGetRecord()
        var
            headerToDelete: Record "Purchase Header";
            linesToDelete: Record "Purchase Line";

        begin
            if (PurchaseHeader.GetFilters = '') then begin
                error('Der skal være filter på ordretype og ordrenummer');
            end;
            if PurchaseHeader.Count() > 1 then error('Man kan kun slette een ordre ad gangen');
            headerToDelete.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
            headerToDelete.Delete(false); //do not execure any OnDelete triggercode
            linesToDelete.Reset();
            linesToDelete.SetRange("Document Type",PurchaseHeader."Document Type");
            linesToDelete.setrange("Document No.",PurchaseHeader."No.");
            linesToDelete.DeleteAll(false); //do not execute any OnDelete triggercode
            message(strsubstno('%1 %2 blev slettet',PurchaseHeader."Document Type",PurchaseHeader."No."));
        end;
        }

    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field("Purchasedocument Type";pDocType)
                    {
                        ApplicationArea = All;    

                    }
                field("Purchasedocument Number";pDocNo)
                    {
                        ApplicationArea = All;
                        Lookup = true;    
                        trigger OnLookup(var lookedUpValue: Text) lookupPerformed: Boolean
                        var
                            lookupForm: Page "Purchase List";
                            lookupTable: Record "Purchase Header";

                        begin
                            lookupPerformed := false;
                            clear(lookedUpValue);
                            clear(pDocNo);
                            lookupTable.reset();
                            lookupTable.SetRange("Document Type",pDocType);
                            //lookupTable.SetRange("No.",PurchaseHeader."No.");
                            lookupForm.LookupMode(true);
                            lookupForm.SetTableView(lookupTable);
                            case lookupForm.RunModal() of
                                action::LookupOK : begin
                                    lookupForm.GetRecord(lookupTable);
                                    pDocNo := lookupTable."No.";
                                    lookedUpValue := lookupTable."No.";
                                    lookupPerformed := true
                                end;
                            end; //case
                        end; 
                    }
            }
        }

    
        // actions
        // {
        //     area(processing)
        //     {
        //         action(ActionName)
        //         {
        //             ApplicationArea = All;
        //             trigger OnAction()
        //             var

        //             begin
        //                 message('kør');

        //             end;
                    
        //         }
        //     }
        // }        
    }
    
    // rendering
    // {
    //     layout(LayoutName)
    //     {
    //         Type = RDLC;
    //         LayoutFile = 'mylayout.rdl';
    //     }
    // }
    
    var
        pDocType: Enum "Purchase Document Type";
        pDocNo: code[20];

}