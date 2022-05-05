public class FieloSObjectService {

    public static void processEvents(List<SObject> events) {
        Set<Id> recordIds = new Set<Id>();

        String objectApiName = ((EventBus.ChangeEventHeader) events.get(0).get('ChangeEventHeader')).entityName;
        Boolean hasActionWithoutCondition = false;
        Set<String> actionFields = new Set<String>();

        for(FieloPLT__Action__c action : [SELECT FieloPLT__ConditionField__c
                                    FROM FieloPLT__Action__c
                                    WHERE FieloPLT__RuleTrigger__r.FieloPLT__Object__c = :objectApiName
                                        AND FieloPLT__Active__c = true]) {
            if (String.isNotBlank(action.FieloPLT__ConditionField__c)) {
                actionFields.add(action.FieloPLT__ConditionField__c);
            } else if (!hasActionWithoutCondition){
                hasActionWithoutCondition = true;
            }
        }

        for (SObject event : events) {
            EventBus.ChangeEventHeader header = (EventBus.ChangeEventHeader) event.get('ChangeEventHeader');

            if (header.changetype == 'CREATE') {
                recordIds.addAll(new Set<Id>((List<Id>) header.recordIds));
            } else if ((header.changetype == 'UPDATE')) {
                for (String field : header.changedFields) {
                    if (actionFields.contains(field) || actionFields.isEmpty() || hasActionWithoutCondition) {
                        recordIds.addAll(new Set<Id>((List<Id>) header.recordIds));
                        break;
                    }
                }
            }
        }

        if (!recordIds.isEmpty()) {
            List<Opportunity> records = (List<Opportunity>) Database.query(
                'SELECT ' + String.join(new List<String>(SObjectType.Opportunity.fields.getMap().keySet()), ',') +
                ' FROM Opportunity WHERE Id IN :recordIds'
            );

            FieloPLT.SObjectService.processRecords(records,null);
        }
    }

    public static void insertError(Exception except){
        FieloPLT__ErrorLog__c error = new FieloPLT__ErrorLog__c();

        error.FieloPLT__LineNumber__c = except.getLineNumber();
        error.FieloPLT__Message__c = except.getMessage();
        error.FieloPLT__StackTrace__c = except.getStackTraceString();
        error.FieloPLT__Type__c = except.getTypeName();
        error.FieloPLT__UserId__c = UserInfo.getUserId();

        insert error;
    }
}