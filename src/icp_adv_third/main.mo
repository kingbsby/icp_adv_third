import IC "./ic";
import List "mo:base/List";
// import bool "mo:base/Bool";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Hash "mo:base/Hash";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Types "./types";

actor class () = self {
    var members : [Principal] = [Principal.fromText("ea234-ybq7w-wyeio-57ez3-kl6f2-rpoub-gjeyc-kywyq-qjsze-heo7r-tae"),
                                Principal.fromText("r7inp-6aaaa-aaaaa-aaabq-cai"),
                                Principal.fromText("ea234-ybq7w-wyeio-57ez3-kl6f2-rpoub-gjeyc-kywyq-qjsze-heo7r-tae")];
    var canisters : List.List<Principal> = List.nil<Principal>();
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
        canisters := List.push(result.canister_id, canisters);
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
    public shared({caller}) func add_proposal(content : Text, exeMethod : Types.ExecuteMethod) : async Types.Proposal{
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
        };
        // proposalsTrie := List.push<Types.Proposal>(proposal, proposals);
        proposalsTrie := Trie.put(proposalsTrie, {hash = Hash.hash(proposalId); key = proposalId},
                                Nat.equal, proposal).0;
        proposal
    };

    //vote for a proposal
    public shared({caller}) func vote(proposal_id : Nat) : async (){
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
                };
                // if (List.size(p.proposal_approvers) == PASS_NUM) p.proposal_completed := true;
                proposalsTrie := Trie.replace(proposalsTrie, {hash = Hash.hash(proposal_id); key = proposal_id},
                                Nat.equal, ?new_proposal).0;
            }
        };

        if(exeFlag){
            addMember(Option.unwrap(proposalMaker));
        };
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

    // get proposals
    public shared({caller}) func get_proposals() : async Trie.Trie<Nat, Types.Proposal>{
        proposalsTrie
    };


};
