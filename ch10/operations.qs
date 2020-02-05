// operations.qs: Sample code for Grover's search (Chapter 10).
//
// Copyright (c) Sarah Kaiser and Chris Granade.
// Code sample from the book "Learn Quantum Computing with Python and Q#" by
// Sarah Kaiser and Chris Granade, published by Manning Publications Co.
// Book ISBN 9781617296130.
// Code licensed under the MIT License.
//

// tag::open_stmts[]
namespace GroverSearch { 
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Arithmetic;

    open Microsoft.Quantum.Preparation;                              
    open Microsoft.Quantum.Math;
    // end::open_stmts[]

    // tag::grover_search[]
    operation SearchList(                                             // <1>
        nQubits : Int,                                                // <2>
        markItem : ((Qubit[], Qubit) => Unit is Adj)                  // <3>
    )
    : Int {                                                           // <4>
        using (qubits = Qubit[nQubits]) {                             // <5>
            PrepareInitialState(qubits);                              // <6>

            for (idxIteration in 0..NIterations(nQubits) - 1) {       // <7>
                ReflectAboutMarkedState(markItem, qubits);
                ReflectAboutInitialState(PrepareInitialState, qubits);
            }

            return MeasureInteger(LittleEndian(qubits));              // <8>
        }
    }
    // end::grover_search[]

    // tag::prepare_all_ones[]
    operation PrepareAllOnes(register : Qubit[]) : Unit is Adj + Ctl {
        ApplyToEachCA(X, register);                                     // <1>
    }
    // end::prepare_all_ones

    // tag::reflect_about_all_ones[]
    operation ReflectAboutAllOnes(register : Qubit[]) : Unit is Adj + Ctl {
        Controlled Z(Most(register), Tail(register));                   // <1>
    }
    // end::reflect_about_all_ones[]

    // tag::initial_state_reflect[]
    operation PrepareInitialState(register : Qubit[]) : Unit is Adj + Ctl {
        ApplyToEachCA(H, register);                                     // <1>
    }

    operation ReflectAboutInitialState(
        prepareInitialState : (Qubit[] => Unit is Adj),                 // <2>
        register : Qubit[]                                              // <3>
    )
    : Unit {
        within {                                                        // <4>
            Adjoint prepareInitialState(register);                      // <5>
            PrepareAllOnes(register);                                   
        } apply {
            ReflectAboutAllOnes(register);                              // <7>
        }
    }
    // end::initial_state_reflect[]

    // tag::marked_reflection[]
    operation ReflectAboutMarkedState(
        markedItemOracle : ((Qubit[], Qubit) => Unit is Adj),           // <1>
        inputQubits : Qubit[])                                          // <2>
    : Unit is Adj {
        using (flag = Qubit()) {                                        // <3>
            within {
                H(flag);                                                // <4>
                X(flag);
            } apply{
                markedItemOracle(inputQubits, flag);                    // <5>                                        
            }
        }
    }
    // end::marked_reflection[]

    function NIterations(nQubits : Int) : Int {
        let nItems = 1 <<< nQubits;
        let angle = ArcSin(1. / Sqrt(IntAsDouble(nItems)));
        let nIterations = Round(0.25 * PI() / angle - 0.5);
        return nIterations;
    }

    operation ApplyOracle(
        idxMarkedItem : Int, 
        register : Qubit[], 
        flag : Qubit) 
    : Unit is Adj + Ctl {
        (ControlledOnInt(idxMarkedItem, X))(register, flag);
    }

    operation RunGroverSearch() : Unit {
        let idxMarkedItem = 6;
        let markItem = ApplyOracle(idxMarkedItem, _, _);
        let foundItem = SearchList(3, markItem);
        Message($"marked {idxMarkedItem} and found {foundItem}.");
    }
}
