import List "mo:base/List";

module {
    public type Proposal = {
        proposal_id : Nat;
        proposal_maker : Principal;
        proposal_content : Text;
        proposal_approvers : List.List<Principal>;
        proposal_completed: Bool;
        proposal_total: Nat;
        proposal_exe_method : ExecuteMethod;
        proposal_exe_target : Principal;
    };

    public type ExecuteMethod = {
        #addMember;
        #delMember;
        #addRestriction;
        #removeRestriction;
    };

    public type Canister = Principal;
    public type CanisterInfo = {canister : Canister; beRestricted : Bool};
}