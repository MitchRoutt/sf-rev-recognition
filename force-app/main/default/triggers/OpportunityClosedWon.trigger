trigger OpportunityClosedWon on Opportunity (after update) {

    List<Id> closedWonIds = new List<Id>();

    for(Opportunity opp : Trigger.new) {

        // Only add the Opportunity Id if the StageName was changed to "Closed Won"
        Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
        if(opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
            
            closedWonIds.add(opp.Id);
        }
    }

    if(closedWonIds.size() > 0) {

        CreateOpportunityLineItemSchedules.createSchedulesForOpportunities(closedWonIds);
    }
}