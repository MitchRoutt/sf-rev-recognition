trigger OpportunityClosedWon on Opportunity (after update) {

    List<Id> closedWonIds = new List<Id>();

    for(Opportunity opp : Trigger.new) {

        if(opp.StageName == 'Closed Won') {

            closedWonIds.add(opp.Id);
        }
    }

    if(closedWonIds.size() > 0) {

        CreateOpportunityLineItemSchedules.createSchedulesForOpportunities(closedWonIds);
    }
}