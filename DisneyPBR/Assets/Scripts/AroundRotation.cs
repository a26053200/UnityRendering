
using System;
using UnityEngine;

public class AroundRotation : MonoBehaviour
{
    public GameObject target;
    public float speed = 0.5f;
    private void Update()
    {
        if(target)
            transform.RotateAround(target.transform.position, Vector3.up, speed);
    }
}
