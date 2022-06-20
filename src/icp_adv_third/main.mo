import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import IC "./ic";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Types "./types";

actor class (m : Nat, memberArray : [Principal]) = self {
    var members : [Principal] = memberArray;
    var canisters : HashMap.HashMap<Types.Canister, Bool> = HashMap.HashMap<Types.Canister, Bool>(0, func(x: Types.Canister,y: Types.Canister) {x==y}, Principal.hash);
    // var canisters : List.List<Principal> = List.nil<Principal>();
    // var proposals : List.List<Types.Proposal> = List.nil<Types.Proposal>();
    var proposalsTrie : Trie.Trie<Nat, Types.Proposal> = Trie.empty();
    var proposalId : Nat = 0;
    let PASS_NUM : Nat = 2;

    public func create_canister() : async IC.canister_id {
        let settings = {
            freezing_threshold = null;
            controllers = ?[Principal.fromActor(self)];
            memory_allocation = null;
            compute_allocation = null;
        };
        let ic : IC.Self = actor("aaaaa-aa");
        let result = await ic.create_canister({ settings = ?settings; });
        canisters.put(result.canister_id, false);
        result.canister_id
    };

    public func install_code(canister_id : IC.canister_id, wasm_module : IC.wasm_module) : async (){
        let ic : IC.Self = actor("aaaaa-aa");
        await ic.install_code ({
            arg = []; 
            wasm_module = wasm_module;
            mode = #install;
            canister_id = canister_id;
        });
    };

    public func start_canister(canister_id : IC.canister_id) : async (){
        let ic : IC.Self = actor("aaaaa-aa");
        await ic.start_canister({canister_id = canister_id});
    };

    public func stop_canister(canister_id : IC.canister_id) : async (){
        let ic : IC.Self = actor("aaaaa-aa");
        await ic.stop_canister({canister_id = canister_id});
    };

    public func delete_canister(canister_id : IC.canister_id) : async (){
        let ic : IC.Self = actor("aaaaa-aa");
        await ic.delete_canister({canister_id = canister_id});
    };

    // add a proposal
    public shared({caller}) func add_proposal(content : Text, exeMethod : Types.ExecuteMethod, principal : Principal) : async Types.Proposal{
        assert(check_member(caller));
        proposalId := proposalId + 1;

        let proposal : Types.Proposal = {
            proposal_id = proposalId;
            proposal_maker = caller;
            proposal_content = content;
            proposal_approvers = List.nil<Principal>();
            proposal_completed = false;
            proposal_total = members.size();
            proposal_exe_method = exeMethod;
            proposal_exe_target = principal;
        };
        // proposalsTrie := List.push<Types.Proposal>(proposal, proposals);
        proposalsTrie := Trie.put(proposalsTrie, {hash = Hash.hash(proposalId); key = proposalId},
                                Nat.equal, proposal).0;
        proposal
    };

    //vote for a proposal
    public shared({caller}) func propose(proposal_id : Nat) : async (){
        assert(check_member(caller));
        
        var exeFlag : Bool = false;
        var proposalMaker : ?Principal = null;
        let proposal = Trie.get(proposalsTrie, {hash = Hash.hash(proposal_id); key = proposal_id;}, Nat.equal);
        switch (proposal){
            case (null) Debug.print("proposal_id not exists");
            case (?p) {
                let new_proposal : Types.Proposal = {
                    proposal_id = p.proposal_id;
                    proposal_maker = p.proposal_maker;
                    proposalMaker = p.proposal_maker;
                    proposal_content = p.proposal_content;
                    proposal_approvers = List.push(caller, p.proposal_approvers);
                    proposal_completed = if (List.size(p.proposal_approvers) + 1 >= PASS_NUM) true else false;
                    proposal_total = members.size();
                    proposal_exe_method = p.proposal_exe_method;
                    proposal_exe_target = p.proposal_exe_target;
                    
                };
                proposalsTrie := Trie.replace(proposalsTrie, {hash = Hash.hash(proposal_id); key = proposal_id},
                                Nat.equal, ?new_proposal).0;
                Debug.print("proposal_approvers count:" # Nat.toText(List.size(new_proposal.proposal_approvers)) #
                "    PASS_NUM :" # Nat.toText(PASS_NUM));
                if (List.size(new_proposal.proposal_approvers) == PASS_NUM) {
                    Debug.print("execute :" # Principal.toText(new_proposal.proposal_exe_target));
                    execute_proposal(new_proposal.proposal_exe_method, new_proposal.proposal_exe_target);
                };
            }
        };
    };

    // show members
    public shared({caller}) func allMembers() : async [Principal] {
        members
    };

    // get proposals
    public shared({caller}) func get_proposals() : async Trie.Trie<Nat, Types.Proposal>{
        proposalsTrie
    };

    // get canisters
    public shared({caller}) func get_canisters() : async List.List<Types.CanisterInfo>{
        var canisterInfo : List.List<Types.CanisterInfo> = List.nil<Types.CanisterInfo>();
        for (can in canisters.entries()){
            let ci : Types.CanisterInfo = { canister = can.0; beRestricted = can.1};
            canisterInfo := List.push(ci, canisterInfo);
        };
        canisterInfo
    };

    // check if caller is in member list
    func check_member(principal : Principal) : Bool{
        let l = List.fromArray(members);
        List.some(l, func (a : Principal) : Bool { a == principal})
    };

    // add proposal maker to member list
    func addMember(principal : Principal) {
        var memberList = List.fromArray(members);
        members := List.toArray(List.push(principal, memberList));
    };

    // add restriction for canister
    func add_restriction(canister : Types.Canister) : (){
        Debug.print("add_restriction : " # Principal.toText(canister));
        ignore canisters.replace(canister, true);
    };

    // remove restriction for canister
    func remove_restriction(canister : Types.Canister) : (){
        ignore canisters.replace(canister, false);
    };

    // execute proposal
    func execute_proposal(method : Types.ExecuteMethod, target : Principal) : (){
        switch(method){
            case (#addRestriction) {
                add_restriction(target);
            };
            case (#removeRestriction) {
                remove_restriction(target);
            };
            case (_) ();
        }
    };
};
