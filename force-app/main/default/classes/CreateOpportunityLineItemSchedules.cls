global with sharing class CreateOpportunityLineItemSchedules {

    @InvocableMethod
    public static void createSchedulesForOpportunities(List<String> opportunityIds) {

        for(String opportunityId : opportunityIds) {

            createSchedulesForSingleOpportunity(opportunityId);
        }
    }

    private static void createSchedulesForSingleOpportunity(String opportunityId) {

        List<OpportunityLineItemSchedule> schedulesToInsert = new List<OpportunityLineItemSchedule>();

        Opportunity opportunity = [SELECT Id, Term_Start_Date__c, Term_End_Date__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

        // Get all of the OpportunityLineItem records for the Opportunity
        List<OpportunityLineItem> lineItems = [SELECT Id, TotalPrice, ServiceDate, End_Date__c, Product2Id, Quantity, Product2.Product_Type__c 
                                                FROM OpportunityLineItem WHERE OpportunityId = :opportunityId];

        System.debug('Number of lineItems is: ' + lineItems.size());

        deleteExistingSchedulesForLineItems(lineItems);

        for(OpportunityLineItem lineItem : lineItems) {

            if(lineItem.Product2.Product_Type__c == 'Subscription') {

                System.debug('Line Item Type was Subscription');

                // If the line item has dates, use them. Otherwise use the Opportunity dates
                Date startDate = lineItem.ServiceDate == null ? opportunity.Term_Start_Date__c : lineItem.ServiceDate;
                Date endDate = lineItem.End_Date__c == null ? opportunity.Term_End_Date__c : lineItem.End_Date__c;

                //Figure out how many monthly schedule records to create for this line item
                schedulesToInsert.addAll(createMonthlySchedules(startDate, endDate, lineItem));
            }
        }

        insert schedulesToInsert;
    }

    private static void deleteExistingSchedulesForLineItems(List<OpportunityLineItem> lineItems) {

        List<Id> lineItemIds = new List<Id>();

        for(OpportunityLineItem lineItem : lineItems) {

            lineItemIds.add(lineItem.Id);
        }
        
        List<OpportunityLineItemSchedule> schedulesToDelete = [SELECT Id FROM OpportunityLineItemSchedule WHERE OpportunityLineItemId IN :lineItemIds ];

        delete schedulesToDelete;
    }

    private static List<OpportunityLineItemSchedule> createMonthlySchedules(Date startDate, Date endDate, OpportunityLineItem lineItem) {

        //TODO: Make this configurable rather than for a static 12 months
        Decimal monthlyPrice = lineItem.TotalPrice / 12;

        List<OpportunityLineItemSchedule> schedules = new List<OpportunityLineItemSchedule>();

        Date periodStartDate = startDate;

        while(periodStartDate < endDate) {

            System.debug('PeriodStartDate is: ' + periodStartDate.format() + ' EndDate is: ' + endDate.format());

            OpportunityLineItemSchedule schedule = new OpportunityLineItemSchedule();
            schedule.OpportunityLineItemId = lineItem.Id;
            schedule.Type = 'Revenue';
            schedule.Revenue = monthlyPrice;
            schedule.ScheduleDate = periodStartDate;
            schedule.Product_ID__c = lineItem.Product2Id;
            schedule.Term_Start_Date__c = startDate;
            schedule.Term_End_Date__c = endDate;

            schedules.add(schedule);

            periodStartDate = periodStartDate.addMonths(1);
        }

        return schedules;
    }
}