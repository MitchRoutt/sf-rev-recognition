/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class CreateOpportunityLineItemSchedulesTests {

    @isTest
    static void canCreateMonthlyScheduleForOneYear() {
        
        Product2 basicSubscription = new Product2();
        basicSubscription.Name = 'Basic License';
        basicSubscription.Product_Type__c = 'Subscription';
        basicSubscription.CanUseRevenueSchedule = true;
        // basicSubscription.NumberOfRevenueInstallments = 12;
        // basicSubscription.RevenueInstallmentPeriod = 'Monthly';
        // basicSubscription.RevenueScheduleType = 'Divide';
        basicSubscription.IsActive = true;

        insert basicSubscription;

        Id standardPriceBookId = Test.getStandardPricebookId();

        PricebookEntry basicEntry = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = basicSubscription.Id,
            UnitPrice = 120,
            IsActive = true
        );
        insert basicEntry;

        Account account = new Account(Name = 'Test Account');
        insert account;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            AccountId = account.Id,
            Pricebook2Id = standardPriceBookId,
            CloseDate = Date.today().addDays(7)
        );
        insert opp;

        OpportunityLineItem lineItem = new OpportunityLineItem(
            OpportunityId = opp.Id,
            ServiceDate = Date.Today(),
            End_Date__c = Date.Today().addYears(1).addDays(-1),
            Product2Id = basicSubscription.Id,
            Quantity = 1,
            TotalPrice = 120
        );
        insert lineItem;

        List<String> opportunityIds = new List<String>();
        opportunityIds.add(opp.Id);

        CreateOpportunityLineItemSchedules.createSchedulesForOpportunities(opportunityIds);

        List<OpportunityLineItemSchedule> schedules = [SELECT Id, Revenue FROM OpportunityLineItemSchedule];

        Assert.areEqual(12, schedules.size());

        for(OpportunityLineItemSchedule schedule : schedules) {

            Assert.areEqual(10, schedule.Revenue);
        }

    }
}