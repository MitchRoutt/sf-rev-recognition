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
private class OpportunityClosedWonScheduleTests {

    @TestSetup
    static void createProductAndPriceEntries(){

        Product2 someSubscription = new Product2();
        someSubscription.Name = 'Some License';
        someSubscription.Product_Type__c = 'Subscription';
        someSubscription.CanUseRevenueSchedule = true;
        someSubscription.IsActive = true;

        insert someSubscription;

        Id standardPriceBookId = Test.getStandardPricebookId();

        PricebookEntry someEntry = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = someSubscription.Id,
            UnitPrice = 120,
            IsActive = true
        );
        insert someEntry;

        Account account = new Account(Name = 'Test Account');
        insert account;
    }

    @isTest
    static void canCreateSchedules() {
       
        Account account = [SELECT Id FROM Account LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];        

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            AccountId = account.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            CloseDate = Date.today().addDays(7)
        );
        insert opp;

        OpportunityLineItem lineItem = new OpportunityLineItem(
            OpportunityId = opp.Id,
            ServiceDate = Date.Today(),
            End_Date__c = Date.Today().addYears(1).addDays(-1),
            Product2Id = product.Id,
            Quantity = 1,
            TotalPrice = 120
        );
        insert lineItem;


        opp.StageName = 'Closed Won';
        update opp;

        List<OpportunityLineItemSchedule> schedules = [SELECT Id, Revenue FROM OpportunityLineItemSchedule];

        Assert.areEqual(12, schedules.size());

        for(OpportunityLineItemSchedule schedule : schedules) {

            Assert.areEqual(10, schedule.Revenue);
        }

    }

    @isTest
    static void canCreateSchedulesFromOpportunityDates() {
       
        Account account = [SELECT Id FROM Account LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];        

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            AccountId = account.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            CloseDate = Date.today().addDays(7),
            Term_Start_Date__c = Date.today(),
            Term_End_Date__c = Date.today().addYears(1)
        );
        insert opp;

        OpportunityLineItem lineItem = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = product.Id,
            Quantity = 1,
            TotalPrice = 120
        );
        insert lineItem;


        opp.StageName = 'Closed Won';
        update opp;

        List<OpportunityLineItemSchedule> schedules = [SELECT Id, Revenue FROM OpportunityLineItemSchedule];

        Assert.areEqual(12, schedules.size());

        for(OpportunityLineItemSchedule schedule : schedules) {

            Assert.areEqual(10, schedule.Revenue);
        }

    }
}