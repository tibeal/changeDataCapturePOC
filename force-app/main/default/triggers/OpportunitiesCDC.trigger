trigger OpportunitiesCDC on OpportunityChangeEvent (after insert) {
    try {
        FieloSObjectService.processEvents(Trigger.new);
    } catch (Exception e) {
        FieloSObjectService.insertError(e);
    }
}